import { create } from 'zustand';

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

interface ChatStore {
  messages: ChatMessage[];
  addMessage: (msg: ChatMessage) => void;
  clearMessages: () => void;
}

export const useChatStore = create<ChatStore>((set) => ({
  messages: [],
  addMessage: (msg) => set((s) => ({ messages: [...s.messages, msg] })),
  clearMessages: () => set({ messages: [] }),
}));

interface ThemeStore {
  dark: boolean;
  toggle: () => void;
  setDark: (val: boolean) => void;
}

export const useThemeStore = create<ThemeStore>((set) => ({
  dark: false,
  toggle: () =>
    set((s) => {
      const next = !s.dark;
      document.documentElement.classList.toggle('dark', next);
      localStorage.setItem('theme', next ? 'dark' : 'light');
      return { dark: next };
    }),
  setDark: (val) => {
    document.documentElement.classList.toggle('dark', val);
    set({ dark: val });
  },
}));
