import { NavLink } from "react-router-dom";
import React from "react";

export default function Navbar() {
  return (
    <div className="flex justify-between items-center p-6 px-16 border-b-2 border-black">
      <div className="flex text-black mr-6">
        <img
          src="/componet-logo.png"
          alt="CompoNet Logo"
          className="object-cover h-9 w-48"
        />
      </div>
      <ul className="text-sm ml-auto">
        <li className="inline-block mt-4 lg:inline-block lg:mt-0 text-black hover:text-gray-400 mr-4">
          <NavLink to="/">HOME</NavLink>
        </li>
        <li className="inline-block mt-4 lg:inline-block lg:mt-0 text-black hover:text-gray-400">
          <a
            href="https://forms.gle/gfTvfQfvWVsGenBE7"
            target="_blank"
            rel="noreferrer"
          >
            FEEDBACK
          </a>
        </li>
      </ul>
    </div>
  );
}
