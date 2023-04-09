import React from "react";
import { Point } from "./utils/types";

interface PointProps {
  point: Point;
  onRemove: (option: Point) => void;
}

export default function PlotPoint({ point, onRemove }: PointProps) {
  return (
    <div className="relative inline-block border-2 border-black hover:border-blue-700 hover:bg-gray-200 p-2 w-80 flex ">
      <div className="flex items-start">
        <div className="flex items-center px-2 pt-1">
          <div
            style={{
              height: "1rem",
              width: "1rem",
              backgroundColor: point.color,
            }}
          ></div>
        </div>

        <div className="flex flex-col">
          <span className="pl-2">{point.mpn}</span>
          <span className="pl-2 text-sm underline text-blue-500 flex items-center">
            <a
              href={point.link}
              target="_blank"
              rel="noreferrer"
              className="pr-1"
            >
              {point.manufacturer}
            </a>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={1.5}
              stroke="currentColor"
              className="w-4 h-4"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M13.5 6H5.25A2.25 2.25 0 003 8.25v10.5A2.25 2.25 0 005.25 21h10.5A2.25 2.25 0 0018 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"
              />
            </svg>
          </span>
        </div>
      </div>

      <button
        className="flex hover:bg-gray-100 text-right ml-auto pt-1"
        onClick={() => onRemove(point)}
      >
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
