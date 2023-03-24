import { NavLink } from "react-router-dom";
import React from "react";

export default function Navbar() {
  return (
    <div className="flex justify-between items-center p-6 px-16 border-b-2 border-black">
      <div className="flex text-black mr-6">
        <svg viewBox="0 0 100 100" width="40" height="40">
          <path
            d="M20,50 L80,50 L80,60 L60,60 L60,80 L40,80 L40,60 L20,60z"
            fill="#000"
            transform="rotate(90, 50, 50)"
          />
        </svg>
        <span className="font-bold text-xl mx-2">CompoNet</span>
        <svg viewBox="0 0 100 100" width="40" height="40">
          <path
            d="M20,50 L80,50 L80,60 L60,60 L60,80 L40,80 L40,60 L20,60z"
            fill="#000"
            transform="rotate(-90, 50, 50)"
          />
        </svg>
      </div>
      <ul className="text-sm ml-auto">
        <li className="inline-block mt-4 lg:inline-block lg:mt-0 text-black hover:text-gray-400 mr-4">
          <NavLink to="/">Home</NavLink>
        </li>
        <li className="inline-block mt-4 lg:inline-block lg:mt-0 text-black hover:text-gray-400 mr-4">
          <NavLink to="/about">About</NavLink>
        </li>
        <li className="inline-block mt-4 lg:inline-block lg:mt-0 text-black hover:text-gray-400">
          <NavLink to="/contact">Contact</NavLink>
        </li>
      </ul>
    </div>
  );
}
