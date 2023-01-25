import React from "react";
import ReactDOM from "react-dom/client";
import "./css/skeleton.css";
import "./css/normalize.css";
import "./css/main.css";
import App from "./App";
import { default as init } from "componet/componet";

init("componet_bg.wasm").then(() => {
  const root = ReactDOM.createRoot(
    document.getElementById("root") as HTMLElement
  );
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
});
