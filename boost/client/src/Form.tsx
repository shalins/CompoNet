import react from "react";
//import Plot from "react-plotly.js";
import Plotly from "plotly.js-basic-dist-min";
import createPlotlyComponent from "react-plotly.js/factory";
import Plot from "react-plotly.js";
import { useEffect, useState } from "react";

//const Plot = createPlotlyComponent(Plotly);

export default function GraphForm() {
  const processCapacitance = (data: any) => {
    return data.map((item: any) => {
      const reg = /([-0-9.])/g;
      const displayValue = item.part_specs_capacitance_display_value;
      let num = parseFloat(displayValue.match(reg).join(""));
      // Convert everything to farads.
      if (displayValue.includes("pF")) {
        num *= 1e-12;
      } else if (displayValue.includes("nF")) {
        num *= 1e-9;
      } else if (displayValue.includes("µF")) {
        num *= 1e-6;
      } else if (displayValue.includes("mF")) {
        num *= 1e-3;
      }
      return num;
    });
  };

  const processPrice = (data: any) => {
    return data.map((item: any) => {
      const reg = /([-0-9.])/g;
      let val = item.part_median_price_1000_converted_price;
      val = val.match(reg).join("");
      val = parseFloat(val);
      return val;
    });
  };

  const [capacitance, setCapacitance] = useState();
  const [price, setPrice] = useState();

  useEffect(() => {
    fetch("/desc?" + new URLSearchParams({ component: "6332" }))
      .then((res) => res.json())
      .then((data) => {
        const capacitances = processCapacitance(data);
        const prices = processPrice(data);
        setCapacitance(capacitances);
        setPrice(prices);
      });
  }, []);

  useEffect(() => {
    console.log("data: ", capacitance);
  }, [capacitance]);

  useEffect(() => {
    console.log("data: ", price);
  }, [price]);

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
                x: capacitance,
                y: price,
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
                title: "Price [$]",
                type: "log",
                autorange: true,
                tickprefix: "$",
              },
            }}
            useResizeHandler
          />
        </div>
      </div>
    </>
  );
}
