import React from "react";
import HomePage from "./pages/HomePage";
import ContactPage from "./pages/ContactPage";
import AboutPage from "./pages/AboutPage";
import { Link, BrowserRouter, Routes, Route } from "react-router-dom";
import Navbar from "./Navbar";

function App() {
  return (
    <div className="container-lg mx-auto">
      <BrowserRouter>
        <Navbar />
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/about" element={<AboutPage />} />
          <Route path="/contact" element={<ContactPage />} />
        </Routes>
      </BrowserRouter>
    </div>
  );
}

export default App;
//<div className="u-max-full-width">
//  <div className="container">
//    <BrowserRouter>
//      <Navbar />
//      <Routes>
//        <Route path="/" element={<HomePage />} />
//        <Route path="/about" element={<AboutPage />} />
//        <Route path="/contact" element={<ContactPage />} />
//      </Routes>
//    </BrowserRouter>
//  </div>
//</div>
