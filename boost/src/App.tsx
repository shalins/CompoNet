import React from "react";
import HomePage from "./pages/HomePage";
import ContactPage from "./pages/ContactPage";
import AboutPage from "./pages/AboutPage";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Navbar from "./Navbar";
// import * as data from "../../data/capacitors/film.json";


function App() {
  return (
	<div className="u-max-full-width">
	<div className="container">
		<BrowserRouter>
			<Navbar />
			<Routes>
				<Route path="/" element={<HomePage />} />
				<Route path="/about" element={<AboutPage />} />
				<Route path="/contact" element={<ContactPage />} />
			</Routes>
		</BrowserRouter>
	</div>
	</div>
  );
}

export default App;
