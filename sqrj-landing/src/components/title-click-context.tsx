"use client";

import { createContext, useContext, type ReactNode } from "react";

const TitleClickContext = createContext<(() => void) | null>(null);

export function TitleClickProvider({
  onClick,
  children,
}: {
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <TitleClickContext.Provider value={onClick}>
      {children}
    </TitleClickContext.Provider>
  );
}

export function useTitleClick() {
  return useContext(TitleClickContext);
}
