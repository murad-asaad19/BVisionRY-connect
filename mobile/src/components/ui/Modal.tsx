import { Modal as RNModal, View, Pressable, KeyboardAvoidingView, Platform } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import type { ReactNode } from 'react';

type Props = {
  visible: boolean;
  onClose?: () => void;
  children: ReactNode;
  testID?: string;
  /** When false, neither the backdrop tap nor the Android hardware back will dismiss the sheet. */
  dismissible?: boolean;
};

export function BottomSheet({
  visible,
  onClose,
  children,
  testID,
  dismissible = true,
}: Props) {
  const handleClose = () => {
    if (!dismissible) return;
    onClose?.();
  };
  return (
    <RNModal visible={visible} animationType="slide" transparent onRequestClose={handleClose}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={{ flex: 1 }}
      >
        <Pressable
          testID={testID ? `${testID}-backdrop` : 'sheet-backdrop'}
          onPress={handleClose}
          accessibilityRole="button"
          accessibilityLabel="Close"
          className="flex-1 bg-navy/50 justify-end"
        >
          <SafeAreaView edges={['bottom']} style={{ backgroundColor: 'transparent' }}>
            <View
              testID={testID}
              onStartShouldSetResponder={() => true}
              // accessibilityViewIsModal traps VoiceOver inside the sheet so
              // it can't jump back to focusable elements behind the backdrop.
              // It belongs on the content View (the actual modal surface), not
              // on the backdrop which exists to dismiss. iOS-only attribute,
              // harmless no-op on Android — no Platform gate required.
              accessibilityViewIsModal
              className="bg-white rounded-t-3xl px-4 pt-3 pb-4"
            >
              <View className="self-center w-9 h-1 bg-border rounded-full mb-3" />
              {children}
            </View>
          </SafeAreaView>
        </Pressable>
      </KeyboardAvoidingView>
    </RNModal>
  );
}
