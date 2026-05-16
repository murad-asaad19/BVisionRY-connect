import { Modal as RNModal, View, Pressable } from 'react-native';
import type { ReactNode } from 'react';

type Props = {
  visible: boolean;
  onClose: () => void;
  children: ReactNode;
  testID?: string;
};

export function BottomSheet({ visible, onClose, children, testID }: Props) {
  return (
    <RNModal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <Pressable
        testID={testID ? `${testID}-backdrop` : 'sheet-backdrop'}
        onPress={onClose}
        accessibilityRole="button"
        accessibilityLabel="Close"
        className="flex-1 bg-navy/50 justify-end"
      >
        <Pressable
          testID={testID}
          onPress={() => {}}
          className="bg-white rounded-t-3xl px-4 pt-3 pb-4"
        >
          <View className="self-center w-9 h-1 bg-border rounded-full mb-3" />
          {children}
        </Pressable>
      </Pressable>
    </RNModal>
  );
}
