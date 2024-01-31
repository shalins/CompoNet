import React, { useState, useRef } from "react";
import { useOutsideClick } from "../hooks/useOutsideClick";

interface DropdownProps {
  defaultText: string;
  selectedOption?: string;
  options: string[];
  onSelect: (option: string) => void;
}

export default function Dropdown({
  defaultText,
  selectedOption,
  options,
  onSelect,
}: DropdownProps) {
  const [showMenu, setShowMenu] = useState(false);

  const handleSelectOption = (option: string) => {
    setShowMenu(!showMenu);
    onSelect(option);
  };

  const ref = useRef();
  useOutsideClick(ref, () => setShowMenu(false));

  return (
    <div
      ref={ref as any}
      className="relative inline-block text-left border-2 border-black min-w-full"
    >
      <div>
        <button
          type="button"
          className="inline-flex justify-between items-center w-full px-4 py-4 text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
          id="options-menu"
          aria-haspopup="true"
          aria-expanded="true"
          onClick={() => setShowMenu(!showMenu)}
        >
          {selectedOption ?? defaultText}
          <svg
            className={`h-5 w-5 ml-2 transition-transform transform ${
              showMenu ? "rotate-180" : ""
            }`}
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fillRule="evenodd"
              d="M5.293 6.707a1 1 0 0 1 1.414 0L10 9.586l3.293-3.293a1 1 0 1 1 1.414 1.414l-4 4a1 1 0 0 1-1.414 0l-4-4a1 1 0 0 1 0-1.414z"
              clipRule="evenodd"
            />
          </svg>
        </button>
      </div>
      {showMenu && (
        <div className="w-full bg-white focus:outline-none absolute z-10 border-2 border-black">
          {options.map((option) => (
            <button
              className="text-left block w-full px-4 py-4 text-sm text-gray-700 hover:bg-gray-200 hover:text-gray-900 border-t border-black"
              role="menuitem"
              onClick={() => handleSelectOption(option)}
              key={options.indexOf(option)}
            >
              {option}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
