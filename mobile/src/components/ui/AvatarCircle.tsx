// Back-compat shim — the canonical primitive is `Avatar`. All existing call
// sites import `AvatarCircle`; they keep working unchanged while Phase 3
// migrations convert them. Re-export the type aliases too so consumers that
// import `AvatarSize` from this module continue to compile.
export { Avatar as AvatarCircle } from './Avatar';
export type { AvatarSize } from './Avatar';
