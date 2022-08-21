import react from 'react';
import Plot from "react-plotly.js";

export default function GraphForm() {
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
					<div className="two columns">
						<label>Year</label>
						<select className="u-full-width" id="exampleRecipientInput">
							<option value="Option 1">2022</option>
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
					  x: [1, 2, 3],
					  y: [2, 6, 3],
					  type: "scatter",
					  mode: "lines+markers",
					  marker: { color: "red" },
					},
					{ type: "bar", x: [1, 2, 3], y: [2, 5, 3] },
				  ]}
				  layout={{ width: 320, height: 240, title: "A Fancy Plot" }}
				/>
				</div>
			</div>
		</>
	);
}
