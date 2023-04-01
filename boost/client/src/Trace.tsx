import React, { useState } from "react";

interface TraceProps {
  title: string;
  color: string;
  onRemove: (option: string) => void;
}

export default function Trace({ title, color, onRemove }: TraceProps) {
  return (
    <div className="relative inline-block text-left border-2 border-black hover:border-blue-700 hover:bg-gray-200 p-2">
      <div className="inline-flex">
        <div className="flex items-center px-2">
          <div className="w-4 h-4" style={{ backgroundColor: color }}></div>
        </div>
        <span className="pr-4">{title}</span>
        <button className="hover:bg-gray-100" onClick={() => onRemove(title)}>
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>
    </div>
  );
}
