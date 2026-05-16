import { useMutation } from '@tanstack/react-query';
import { reportTarget } from '~/features/privacy/services/privacy.service';
import type { ReportReason, ReportTargetType } from '~/features/privacy/services/privacy.service';

type Vars = {
  targetType: ReportTargetType;
  targetId: string;
  reason: ReportReason;
  note: string | null;
};

export function useReportTarget() {
  return useMutation({
    mutationFn: (v: Vars) => reportTarget(v.targetType, v.targetId, v.reason, v.note),
  });
}
