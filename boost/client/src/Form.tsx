import react from "react";
import Plot from "react-plotly.js";
import { useEffect, useState } from "react";
import { Component, parse } from "./parse";

export default function GraphForm() {
  const [components, setComponents] = useState<Component[]>();

  useEffect(() => {
    const searchParams = new URLSearchParams();
    searchParams.append("categories", "6332");
    searchParams.append("categories", "6334");
    searchParams.append("attributes", "Capacitance");
    searchParams.append("attributes", "Weight");

    fetch("/api?" + searchParams.toString())
      .then((res) => res.json())
      .then((data) => {
        //const capacitances = processCapacitance(data);
        //const prices = processPrice(data);
        //setCapacitance(capacitances);
        //setPrice(prices);
        const components = parse(
          data,
          ["Ceramic Capacitors", "Mica Capacitors"],
          ["Capacitance", "Weight"]
        );
        setComponents(components);
      });
  }, []);

  useEffect(() => {
    console.log("data: ", components);
  }, [components]);

  return (
    <>
      <form>
        <div className="row">
          <div className="five columns">
            <label>Passive Component</label>
            <select className="u-full-width" id="exampleRecipientInput">
              <option value="Option 1">Aluminum Electolytic Capacitors</option>
              <option value="Option 2">Ceramic Capacitors</option>
              <option value="Option 3">Film Capacitors</option>
              <option value="Option 4">Mica Capacitors</option>
              <option value="Option 5">Tantalum Capacitors</option>
              <option value="Option 6">Fixed Inductors</option>
              <option value="Option 7">Variable Inductors</option>
            </select>
          </div>
          <div className="three columns">
            <label>Property 1 (X-Axis)</label>
            <select className="u-full-width" id="exampleRecipientInput">
              <option value="Option 1">DC Voltage</option>
              <option value="Option 2">Capacitance</option>
              <option value="Option 3">Dielectric</option>
            </select>
          </div>
          <div className="three columns">
            <label>Property 2 (Y-Axis)</label>
            <select className="u-full-width" id="exampleRecipientInput">
              <option value="Option 1">Capacitance</option>
              <option value="Option 2">DC Voltage</option>
              <option value="Option 3">Dielectric</option>
            </select>
          </div>
        </div>
      </form>
      <div className="row">
        <div className="eleven columns">
          <Plot
            data={[
              {
                x: components?.[0]?.axes?.[0]?.data,
                y: components?.[0]?.axes?.[1]?.data,
                type: "scattergl",
                mode: "markers",
                marker: { color: "navyblue", size: 4 },
              },
            ]}
            layout={{
              autosize: true,
              title: "Ceramic Capacitors",
              xaxis: {
                title: "Capacitance [F]",
                type: "log",
                autorange: true,
                ticksuffix: "F",
              },
              yaxis: {
                title: "Weight [g]",
                type: "log",
                autorange: true,
                ticksuffix: "g",
              },
            }}
            useResizeHandler
          />
        </div>
      </div>
    </>
  );
}
