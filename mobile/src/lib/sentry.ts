import * as React from 'react';
import * as Sentry from '@sentry/react-native';
import Constants from 'expo-constants';
import { env } from '~/lib/env';
import { useTelemetryStore } from '~/features/settings/store/telemetryStore';

let initialized = false;

const TOKEN_QUERY_RE = /([?&])(access_token|refresh_token)=[^&#]*/gi;
const TOKEN_FRAGMENT_RE = /#(?:[^&\s]*&)*(?:access_token|refresh_token)=[^&\s]*(?:&[^&\s]*)*/gi;

/**
 * Redacts Supabase auth tokens (and similar bearer tokens) from a string —
 * primarily URLs that may appear in breadcrumbs, request data, or stack traces.
 * Strips `?access_token=…`, `&refresh_token=…`, and `#access_token=…` fragments.
 */
export function redactTokens(s: string): string {
  if (!s) return s;
  return s
    .replace(TOKEN_QUERY_RE, (_m, sep) => `${sep}access_token=REDACTED`)
    .replace(TOKEN_FRAGMENT_RE, '#REDACTED');
}

function containsToken(s: unknown): boolean {
  return typeof s === 'string' && /access_token|refresh_token/i.test(s);
}

// Headers that carry bearer credentials in plaintext. Substring-based redaction
// of `redactTokens` can't catch these — the raw value is the token. Replace
// the value entirely when the key matches.
const AUTH_HEADER_RE = /^(authorization|apikey|x-api-key|sb-[\w-]*-auth-token|cookie|set-cookie)$/i;
function redactAuthHeaders(headers: Record<string, unknown>) {
  for (const key of Object.keys(headers)) {
    if (AUTH_HEADER_RE.test(key)) {
      headers[key] = 'REDACTED';
    }
  }
}

/**
 * Recursively redact tokens in any string leaf reachable from `value`.
 *
 * Walks plain objects and arrays in-place; mutates only string properties via
 * `redactTokens`. Uses a `WeakSet` to short-circuit reference cycles (Sentry
 * payloads can self-reference via integrations) and skips non-plain objects
 * (Errors, Dates, typed arrays, class instances) to avoid clobbering their
 * internal shape — Sentry serializes those itself before transport.
 *
 * Bounded by `MAX_DEPTH` so a pathological structure can't blow the stack.
 */
const MAX_DEPTH = 8;
function isPlainObject(v: unknown): v is Record<string, unknown> {
  if (v == null || typeof v !== 'object') return false;
  const proto = Object.getPrototypeOf(v);
  return proto === Object.prototype || proto === null;
}

function redactDeep(value: unknown, seen: WeakSet<object>, depth: number): unknown {
  if (depth > MAX_DEPTH) return value;
  if (typeof value === 'string') return redactTokens(value);
  if (value == null || typeof value !== 'object') return value;
  if (seen.has(value as object)) return value;
  seen.add(value as object);
  if (Array.isArray(value)) {
    for (let i = 0; i < value.length; i++) {
      value[i] = redactDeep(value[i], seen, depth + 1);
    }
    return value;
  }
  if (!isPlainObject(value)) return value;
  for (const key of Object.keys(value)) {
    value[key] = redactDeep(value[key], seen, depth + 1);
  }
  return value;
}

/**
 * Sentry ErrorBoundary preconfigured with a null fallback so crashes don't
 * paint a stale tree, but the surrounding navigation chrome (rendered by an
 * outer parent, if any) remains. Consumers wrap their subtree in this; the
 * default `showDialog` is off because we have no native feedback widget set up.
 *
 * `Sentry.ErrorBoundary` requires a `fallback` prop, so callers can't use the
 * raw export bare — this wrapper supplies the contract.
 */
export function SentryErrorBoundary({ children }: { children: React.ReactNode }) {
  return React.createElement(
    Sentry.ErrorBoundary,
    { fallback: null, showDialog: false },
    children
  );
}

export function initSentry() {
  if (initialized) return;
  if (!env.SENTRY_DSN) {
    return; // No-op if DSN is unset
  }
  // Best-effort opt-out: read the persisted pref synchronously. If the store
  // hasn't rehydrated from AsyncStorage yet, this returns the default (true).
  // Pref changes via Settings take effect on the NEXT app launch.
  if (!useTelemetryStore.getState().crashReportsEnabled) {
    return;
  }
  const isProd = env.SENTRY_ENV === 'prod' || env.SENTRY_ENV === 'production';
  const runtimeVersion = Constants.expoConfig?.runtimeVersion;
  const release =
    Constants.expoConfig?.version ??
    (typeof runtimeVersion === 'string' ? runtimeVersion : undefined);
  Sentry.init({
    dsn: env.SENTRY_DSN,
    environment: env.SENTRY_ENV,
    release,
    enableNativeCrashHandling: true,
    enableAutoSessionTracking: true,
    sendDefaultPii: false,
    tracesSampleRate: isProd ? 0.05 : 1.0,
    beforeBreadcrumb(breadcrumb) {
      // Drop console/xhr/fetch breadcrumbs that carry raw tokens.
      const url = (breadcrumb.data as { url?: unknown } | undefined)?.url;
      if (containsToken(breadcrumb.message) || containsToken(url)) {
        if (
          breadcrumb.category === 'console' ||
          breadcrumb.category === 'xhr' ||
          breadcrumb.category === 'fetch'
        ) {
          return null;
        }
      }
      if (breadcrumb.data) {
        const data = { ...breadcrumb.data } as Record<string, unknown>;
        if (typeof data.url === 'string') data.url = redactTokens(data.url);
        if (typeof data.to === 'string') data.to = redactTokens(data.to);
        if (typeof data.from === 'string') data.from = redactTokens(data.from);
        if (data.headers && typeof data.headers === 'object') {
          redactAuthHeaders(data.headers as Record<string, unknown>);
        }
        breadcrumb.data = data;
      }
      if (typeof breadcrumb.message === 'string') {
        breadcrumb.message = redactTokens(breadcrumb.message);
      }
      return breadcrumb;
    },
    beforeSend(event) {
      // Strip PII from user object.
      if (event.user) {
        event.user = { id: event.user.id };
      }
      // Recursively redact tokens in every structured surface that can carry
      // user data. A shared `WeakSet` guards against shared references across
      // these surfaces.
      const seen = new WeakSet<object>();

      // Top-level string fields. Sentry routinely includes the error message
      // verbatim in `event.message` and the route name in `event.transaction`
      // — both can echo back the URL that triggered the error.
      if (typeof event.message === 'string') {
        event.message = redactTokens(event.message);
      }
      if (typeof event.transaction === 'string') {
        event.transaction = redactTokens(event.transaction);
      }

      // Request object: url, headers, query_string, data. Each can carry the
      // auth token in different ways (Authorization header, magic-link URLs
      // pasted into the fetch call, etc).
      if (event.request) {
        if (typeof event.request.url === 'string') {
          event.request.url = redactTokens(event.request.url);
        }
        if (event.request.headers && typeof event.request.headers === 'object') {
          redactAuthHeaders(event.request.headers as Record<string, unknown>);
          redactDeep(event.request.headers, seen, 0);
        }
        if (typeof event.request.query_string === 'string') {
          event.request.query_string = redactTokens(event.request.query_string);
        } else if (
          event.request.query_string != null &&
          typeof event.request.query_string === 'object'
        ) {
          redactDeep(event.request.query_string, seen, 0);
        }
        if (typeof event.request.data === 'string') {
          event.request.data = redactTokens(event.request.data);
        } else if (event.request.data != null && typeof event.request.data === 'object') {
          redactDeep(event.request.data, seen, 0);
        }
      }

      // Tags are user-attached key/value pairs; nothing prevents a caller
      // from tagging a span with the failing URL.
      if (event.tags && typeof event.tags === 'object') {
        redactDeep(event.tags, seen, 0);
      }

      // Contexts / extras / breadcrumbs / stack-frame vars — pre-existing
      // surfaces that already get the deep walk.
      if (event.contexts) redactDeep(event.contexts, seen, 0);
      if (event.extra) redactDeep(event.extra, seen, 0);
      if (event.breadcrumbs) {
        event.breadcrumbs = event.breadcrumbs.map((b) => {
          if (b.data) redactDeep(b.data, seen, 0);
          if (typeof b.message === 'string') b.message = redactTokens(b.message);
          return b;
        });
      }
      if (event.exception?.values) {
        for (const value of event.exception.values) {
          // The thrown error's class name and message — both surface in the
          // Sentry UI and can include the URL that triggered the throw
          // (e.g. supabase-js wraps fetch failures with the request URL).
          if (typeof value.value === 'string') {
            value.value = redactTokens(value.value);
          }
          if (typeof value.type === 'string') {
            value.type = redactTokens(value.type);
          }
          const frames = value.stacktrace?.frames;
          if (!frames) continue;
          for (const frame of frames) {
            if (frame.vars) redactDeep(frame.vars, seen, 0);
          }
        }
      }
      return event;
    },
  });
  initialized = true;
}

export { Sentry };
