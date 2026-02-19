import { CopyButton } from "./copy-button";

interface ConversationActionsProps {
  onToast: (data: {
    title: string;
    subtitle?: string;
    type: "success" | "error";
    isLarge?: boolean;
  }) => void;
}

export function ConversationActions({ onToast }: ConversationActionsProps) {
  return (
    <div
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
      }}
    >
      <CopyButton mode="copy" onToast={onToast} />
      <CopyButton mode="save" onToast={onToast} />
    </div>
  );
}
