import { NavLink } from "react-router-dom";
import React from "react";

// import './Navbar.css';

export default function Navbar() {
	return (
			<div className="row">
				<nav className="eleven columns">
					<div className="one column">
						<NavLink to="/">Home</NavLink>
					</div>
					<div className="one column">
						<NavLink to="/about">About</NavLink>
					</div>
					<div className="one column">
						<NavLink to="/contact">Contact</NavLink>
					</div>
				</nav>
			</div>
	);
}
