import React, { useState } from "react";
import { Trace } from "./utils/types";

interface TraceProps {
  trace: Trace;
  onRemove: (option: Trace) => void;
}

export default function PlotTrace({ trace, onRemove }: TraceProps) {
  return (
    <div className="relative inline-block text-left border-2 border-black hover:border-blue-700 hover:bg-gray-200 p-2 flex flex-wrap">
      <div className="flex px-2 items-center">
        <div
          style={{
            height: "1rem",
            width: "1rem",
            backgroundColor: trace.color,
          }}
        ></div>
      </div>
      <span className="pr-4">{trace.title}</span>
      <button className="hover:bg-gray-100" onClick={() => onRemove(trace)}>
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
  );
}
