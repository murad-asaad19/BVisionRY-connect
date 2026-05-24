import { useState } from 'react';
import { View, Text, ScrollView, Pressable, Switch } from 'react-native';
import { router } from 'expo-router';
import { useTranslation } from 'react-i18next';
import { Input } from '~/components/ui/Input';
import { Button } from '~/components/ui/Button';
import { Pill } from '~/components/ui/Pill';
import { TopBar } from '~/components/ui/TopBar';
import {
  CreateOpportunityInputSchema,
  OpportunityTagsSchema,
  type CreateOpportunityInput,
} from '~/features/opportunities/schemas';
import { useCreateOpportunity } from '~/features/opportunities/hooks/useCreateOpportunity';
import type { OpportunityKind } from '~/features/opportunities/services/opportunities.service';

const ALL_KINDS: OpportunityKind[] = [
  'hiring',
  'seeking_role',
  'fundraising',
  'investing',
  'cofounder',
  'advising',
  'seeking_advisor',
  'collaboration',
];

const TITLE_MAX = 120;
const BODY_MAX = 2000;
const TAG_MAX = 8;

type Step = 1 | 2 | 3;

type DraftState = {
  kind: OpportunityKind | null;
  title: string;
  body: string;
  tagsInput: string;
  locationCity: string;
  locationCountry: string;
  remoteOk: boolean;
  expiresAt: string | null;
};

const EMPTY_DRAFT: DraftState = {
  kind: null,
  title: '',
  body: '',
  tagsInput: '',
  locationCity: '',
  locationCountry: '',
  remoteOk: false,
  expiresAt: null,
};

/** Parse the free-form "tag1, tag2" textbox into a normalised array. */
function parseTags(input: string): string[] {
  return input
    .split(/[,\s]+/)
    .map((t) => t.trim().toLowerCase())
    .filter(Boolean)
    .slice(0, TAG_MAX);
}

type Props = {
  onSubmitted?: (id: string) => void;
};

export function OpportunityComposer({ onSubmitted }: Props) {
  const { t } = useTranslation();
  const [step, setStep] = useState<Step>(1);
  const [draft, setDraft] = useState<DraftState>(EMPTY_DRAFT);
  const [errors, setErrors] = useState<Partial<Record<keyof DraftState | 'submit', string>>>({});
  const create = useCreateOpportunity();

  const set = <K extends keyof DraftState>(key: K, value: DraftState[K]) => {
    setDraft((d) => ({ ...d, [key]: value }));
    setErrors((e) => ({ ...e, [key]: undefined }));
  };

  const tags = parseTags(draft.tagsInput);

  // ────────────────────────── step navigation ──────────────────────────
  const validateStep1 = (): boolean => {
    if (!draft.kind) {
      setErrors({ kind: t('opportunities.composer.errorKindRequired') });
      return false;
    }
    return true;
  };

  const validateStep2 = (): boolean => {
    const nextErrors: typeof errors = {};
    if (draft.title.trim().length < 5 || draft.title.length > TITLE_MAX) {
      nextErrors.title = t('opportunities.composer.errorTitle');
    }
    if (draft.body.trim().length < 10 || draft.body.length > BODY_MAX) {
      nextErrors.body = t('opportunities.composer.errorBody');
    }
    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  };

  const validateStep3 = (): boolean => {
    const parsedTags = OpportunityTagsSchema.safeParse(tags);
    if (!parsedTags.success) {
      setErrors({ tagsInput: t('opportunities.composer.errorTags') });
      return false;
    }
    return true;
  };

  const onNext = () => {
    if (step === 1 && validateStep1()) setStep(2);
    else if (step === 2 && validateStep2()) setStep(3);
  };

  const onBack = () => {
    if (step > 1) setStep((s) => (s - 1) as Step);
  };

  // ────────────────────────── submit ───────────────────────────────────
  const onSubmit = async () => {
    if (!draft.kind) return;
    if (!validateStep3()) return;

    const input: CreateOpportunityInput = {
      kind: draft.kind,
      title: draft.title.trim(),
      body: draft.body.trim(),
      tags,
      locationCity: draft.locationCity.trim() || undefined,
      locationCountry: draft.locationCountry.trim() || undefined,
      remoteOk: draft.remoteOk,
      expiresAt: draft.expiresAt,
    };

    const parsed = CreateOpportunityInputSchema.safeParse(input);
    if (!parsed.success) {
      setErrors({ submit: parsed.error.issues[0]?.message ?? t('opportunities.composer.errorSubmit') });
      return;
    }

    try {
      const id = await create.mutateAsync(parsed.data);
      onSubmitted?.(id);
      router.replace({ pathname: '/(app)/opportunities/[id]', params: { id } });
    } catch (e) {
      setErrors({
        submit: e instanceof Error ? e.message : t('opportunities.composer.errorSubmit'),
      });
    }
  };

  return (
    <View testID="opportunity-composer" className="flex-1 bg-surface">
      <TopBar title={t('opportunities.feed.newCta')} />
      <ScrollView className="flex-1" contentContainerStyle={{ padding: 16, paddingBottom: 64 }}>
        {/* Step indicator */}
        <Text className="font-display-bold text-[11px] text-muted uppercase tracking-wide mb-3">
          {t('opportunities.composer.stepCounter', { current: step, total: 3 })}
        </Text>

        {step === 1 ? (
          <View>
            <Text className="font-display-bold text-[16px] text-navy mb-3">
              {t('opportunities.composer.stepKind')}
            </Text>
            <View className="gap-2">
              {ALL_KINDS.map((k) => {
                const active = draft.kind === k;
                return (
                  <Pressable
                    key={k}
                    testID={`opportunity-composer-kind-${k}`}
                    onPress={() => set('kind', k)}
                    accessibilityRole="radio"
                    accessibilityState={{ selected: active }}
                    className={`border-[1.5px] rounded-[10px] px-3 py-3 ${active ? 'border-navy bg-gold-pale' : 'border-border bg-white'}`}
                  >
                    <Text
                      className={`font-display-bold text-[13px] ${active ? 'text-navy' : 'text-body'}`}
                    >
                      {t(`opportunities.kind.${k}`)}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
            {errors.kind ? (
              <Text testID="opportunity-composer-kind-error" className="text-danger-text text-[11px] mt-2">
                {errors.kind}
              </Text>
            ) : null}
          </View>
        ) : null}

        {step === 2 ? (
          <View>
            <Text className="font-display-bold text-[16px] text-navy mb-3">
              {t('opportunities.composer.stepContent')}
            </Text>
            <Input
              testID="opportunity-composer-title"
              label={t('opportunities.composer.titleLabel')}
              value={draft.title}
              onChangeText={(s) => set('title', s)}
              placeholder={t('opportunities.composer.titlePlaceholder')}
              maxLength={TITLE_MAX}
              errorText={errors.title}
            />
            <Input
              testID="opportunity-composer-body"
              label={t('opportunities.composer.bodyLabel')}
              value={draft.body}
              onChangeText={(s) => set('body', s)}
              placeholder={t('opportunities.composer.bodyPlaceholder')}
              multiline
              numberOfLines={6}
              maxLength={BODY_MAX}
              errorText={errors.body}
            />
          </View>
        ) : null}

        {step === 3 ? (
          <View>
            <Text className="font-display-bold text-[16px] text-navy mb-3">
              {t('opportunities.composer.stepMeta')}
            </Text>
            <Input
              testID="opportunity-composer-tags"
              label={t('opportunities.composer.tagsLabel')}
              value={draft.tagsInput}
              onChangeText={(s) => set('tagsInput', s)}
              placeholder={t('opportunities.composer.tagsPlaceholder')}
              autoCapitalize="none"
              autoCorrect={false}
              errorText={errors.tagsInput}
            />
            {tags.length > 0 ? (
              <View className="flex-row gap-1.5 mb-2 flex-wrap">
                {tags.map((tag) => (
                  <Pill key={tag} variant="muted">
                    #{tag}
                  </Pill>
                ))}
              </View>
            ) : null}
            <Input
              testID="opportunity-composer-city"
              label={t('opportunities.composer.cityLabel')}
              value={draft.locationCity}
              onChangeText={(s) => set('locationCity', s)}
              placeholder={t('opportunities.composer.cityLabel')}
              maxLength={80}
            />
            <Input
              testID="opportunity-composer-country"
              label={t('opportunities.composer.countryLabel')}
              value={draft.locationCountry}
              onChangeText={(s) => set('locationCountry', s)}
              placeholder={t('opportunities.composer.countryLabel')}
              maxLength={80}
            />
            <View className="flex-row items-center justify-between my-2">
              <Text className="font-body text-[12px] text-body">
                {t('opportunities.composer.remoteLabel')}
              </Text>
              <Switch
                testID="opportunity-composer-remote"
                value={draft.remoteOk}
                onValueChange={(v) => set('remoteOk', v)}
                accessibilityLabel={t('opportunities.composer.remoteLabel')}
              />
            </View>
            <Text className="font-body text-[11px] text-muted mb-2">
              {t('opportunities.composer.expiresHint')}
            </Text>
            {errors.submit ? (
              <Text
                testID="opportunity-composer-submit-error"
                className="text-danger-text text-[11px] mb-2"
              >
                {errors.submit}
              </Text>
            ) : null}
          </View>
        ) : null}

        {/* Nav buttons */}
        <View className="flex-row gap-3 mt-6">
          {step > 1 ? (
            <View className="flex-1">
              <Button
                testID="opportunity-composer-back"
                variant="outline"
                onPress={onBack}
                disabled={create.isPending}
              >
                {t('opportunities.composer.back')}
              </Button>
            </View>
          ) : null}
          <View className="flex-1">
            {step < 3 ? (
              <Button testID="opportunity-composer-next" variant="primary" onPress={onNext}>
                {t('opportunities.composer.next')}
              </Button>
            ) : (
              <Button
                testID="opportunity-composer-submit"
                variant="primary"
                onPress={onSubmit}
                loading={create.isPending}
              >
                {create.isPending
                  ? t('opportunities.composer.submitting')
                  : t('opportunities.composer.submit')}
              </Button>
            )}
          </View>
        </View>
      </ScrollView>
    </View>
  );
}
