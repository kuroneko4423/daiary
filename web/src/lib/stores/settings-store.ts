import { create } from "zustand";
import { persist } from "zustand/middleware";

interface SettingsState {
  defaultLanguage: string;
  defaultStyle: string;
  defaultLength: string;

  setDefaultLanguage: (language: string) => void;
  setDefaultStyle: (style: string) => void;
  setDefaultLength: (length: string) => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set) => ({
      defaultLanguage: "ja",
      defaultStyle: "casual",
      defaultLength: "medium",

      setDefaultLanguage: (language) => set({ defaultLanguage: language }),
      setDefaultStyle: (style) => set({ defaultStyle: style }),
      setDefaultLength: (length) => set({ defaultLength: length }),
    }),
    {
      name: "settings-storage",
    }
  )
);
