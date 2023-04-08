import { useEffect } from "react";

export function useOutsideClick(ref: any, onClickOut: () => void) {
  useEffect(() => {
    const handleClickOutside = ({ target }: any) =>
      ref.current && !ref.current.contains(target) && onClickOut?.();
    document.addEventListener("click", handleClickOutside);
    return () => document.removeEventListener("click", handleClickOutside);
  }, []);
}
