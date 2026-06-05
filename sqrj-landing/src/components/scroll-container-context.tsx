"use client";

import { createContext, useContext, useRef, type RefObject, type ReactNode } from "react";

interface ScrollContextValue {
  ref: RefObject<HTMLElement | null>;
}

const ScrollContainerContext = createContext<ScrollContextValue | null>(null);

export function ScrollContainerProvider({ children }: { children: ReactNode }) {
  const ref = useRef<HTMLElement | null>(null);
  return (
    <ScrollContainerContext.Provider value={{ ref }}>
      {children}
    </ScrollContainerContext.Provider>
  );
}

export function useScrollContainerRef() {
  const ctx = useContext(ScrollContainerContext);
  return ctx?.ref ?? null;
}
