import React from "react";
import ReactDOM from "react-dom/client";
import "./index.css";
import App from "./interface/App";
import { default as init } from "componet/componet";

init("componet_bg.wasm").then(() => {
  const root = ReactDOM.createRoot(
    document.getElementById("root") as HTMLElement
  );
  root.render(
    <React.StrictMode>
      <div className="max-w-screen max-h-screen">
        <App />
      </div>
    </React.StrictMode>
  );
});
