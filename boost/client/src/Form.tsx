import { ChangeEvent } from "react";
import plotComponentFactory from "react-plotly.js/factory";
import Plotly from "plotly.js/dist/plotly";

import { useEffect, useState } from "react";
import { QueryParser } from "componet/componet";
import { Components, Component } from "./proto/ts/componet.graph";
import { ColumnType } from "./proto/ts/componet.metadata";
import { Affix } from "./proto/ts/componet";
import { COLUMNS } from "./utils/octopart";
import Dropdown from "./Dropdown";
import PlotTrace from "./Trace";
import { Trace, Axis } from "./utils/types";

export default function GraphForm() {
  // Selection Parameters
  const [xAxisAttribute, setXAxisAttribute] = useState<string>();
  const [yAxisAttribute, setYAxisAttribute] = useState<string>();
  const [selectedComponent, setSelectedComponent] = useState<string>();
  const [selectedYear, setSelectedYear] = useState<string>();

  // Data that corresponds to user selections for the plot
  const [plotTraces, setPlotTraces] = useState<Trace[]>([]);
  const [plotComponent, setPlotComponent] = useState<any[]>([]);

  // Actual plot data
  const [plotData, setPlotData] = useState<any[]>([]);
  const [plotLayout, setPlotLayout] = useState<{ [key: string]: any }>({});

  // Raw data from the database
  const [components, setComponents] = useState<Component[]>();

  // Loading data from the database
  const [loading, setLoading] = useState<boolean>(false);

  const traceColors = [
    "#1f77b4",
    "#ff7f0e",
    "#2ca02c",
    "#d62728",
    "#9467bd",
    "#8c564b",
    "#e377c2",
    "#7f7f7f",
    "#bcbd22",
    "#17becf",
  ];

  const handleSelectedAttribute = (selectedAttribute: string, axis: Axis) => {
    const name = COLUMNS.find(
      (attribute) => attribute.name === selectedAttribute
    )?.name;
    if (name) {
      axis === Axis.X ? setXAxisAttribute(name) : setYAxisAttribute(name);
    }
  };

  const onPlotSelectPoint = (event: any) => {
    console.log(event);
    setPlotComponent((prev) => {
      return [...prev, event.points[0]];
    });

    plotData[event.points[0].fullData.index].marker.color[
      event.points[0].pointIndex
    ] = "black";
    plotData[event.points[0].fullData.index].marker.size[
      event.points[0].pointIndex
    ] = "10";
    plotData[event.points[0].fullData.index].marker.symbol[
      event.points[0].pointIndex
    ] = "x";
  };

  const onPlotDeselectPoint = (component: any, i: number) => {
    setPlotComponent((prev) => {
      plotData[component.fullData.index].marker.color[component.pointIndex] =
        traceColors[component.fullData.index];
      plotData[component.fullData.index].marker.size[component.pointIndex] =
        "5";
      plotData[component.fullData.index].marker.symbol[component.pointIndex] =
        "circle";
      return prev.filter((_, index) => index !== i);
    });
  };

  const addToPlot = () => {
    if (
      !xAxisAttribute ||
      !yAxisAttribute ||
      !selectedComponent ||
      !selectedYear
    ) {
      return;
    }

    // Create a Trace from the different selections
    const trace: Trace = {
      title: selectedComponent,
      color: traceColors[plotTraces.length],
      year: selectedYear,
    };
    console.log(trace);

    setPlotTraces((prev) => [...prev, trace]);
  };

  const removeFromPlot = (trace: Trace) => {
    setPlotTraces((prev) => prev.filter((t) => t !== trace));

    // Reset the dropdown
    setSelectedComponent("Select Component");
  };

  // Check if the return data is valid
  const isEmpty = (data: any) => {
    return (
      data &&
      Object.keys(data).length === 0 &&
      Object.getPrototypeOf(data) === Object.prototype
    );
  };

  const graphProps = {
    div: "graph",
    data: plotData,
    layout: plotLayout,
    onClick: onPlotSelectPoint,
    useResizeHandler: true,
  };
  const Plot = plotComponentFactory(Plotly);

  useEffect(() => {
    const computePlot = () => {
      const searchParams = new URLSearchParams();

      plotTraces.forEach((component) => {
        console.warn("Found octopart id for component: ", component);
        const id = COLUMNS.find((c) => c.name === component.title)?.octopartId;
        if (id) {
          searchParams.append("categories", id as unknown as string);
        } else {
          console.warn("Could not find octopart id for component: ", component);
        }
      });

      if (xAxisAttribute && yAxisAttribute) {
        searchParams.append("attributes", xAxisAttribute);
        searchParams.append("attributes", yAxisAttribute);
      }

      fetch("/api?" + searchParams.toString())
        .then((res) => {
          console.log(res);
          return res.json();
        })
        .then((data) => {
          const componentString = QueryParser.parse(
            JSON.stringify(data)
          ) as unknown as string;

          // Convert the string to a Component object.
          if (!isEmpty(JSON.parse(componentString))) {
            const components = Components.fromJSON(
              JSON.parse(componentString)
            ).components;

            setComponents(components);
            graphData(components);
            graphLayout(components);
            setPlotComponent([]);
          } else {
            console.warn("No components in the response");
          }
        });
    };

    computePlot();
  }, [plotTraces]);

  useEffect(() => {
    console.log(components);
  }, [components]);

  const graphData = (components: Component[]) => {
    const data: any[] = [];

    components.forEach((component, i) => {
      const hoverText: string[] = component.mpns.map((_, idx) => {
        return `
MPN: <b>${component.mpns[idx]}</b><br>
				Manufacturer: <b>${component.manufacturers[idx]}</b>`;
      });
      const plotSettings: { [key: string]: any } = {
        x: component.axes?.[0]?.data,
        y: component.axes?.[1]?.data,
        text: hoverText,
        hovertemplate: `
			%{text}
			<br><br>
			%{yaxis.title.text}: %{y} <br>
			%{xaxis.title.text}: %{x} <br>
			<extra></extra>
		`,
        name: component.category
          .replace(" Capacitors", "")
          .replace(" Inductors", ""),
        type: "scattergl",
        mode: "markers",
        marker: {
          color: new Array(component.mpns.length).fill(traceColors[i]),
          symbol: new Array(component.mpns.length).fill("circle"),
          size: new Array(component.mpns.length).fill(4),
        },
      };
      if (component.axes?.length > 2) {
        plotSettings["z"] = component.axes?.[2]?.data;
        plotSettings["type"] = "scatter3d";
      }
      data.push(plotSettings);
    });
    setPlotData(data);
    return data;
  };

  const graphLayout = (components: Component[]) => {
    const layout: { [key: string]: any } = {
      autosize: true,
      xaxis: {
        title: xAxisAttribute + ` [${components[0].axes[0]?.unit}]`,
        type: "log",
        autorange: true,
        ticksuffix:
          components[0].axes[0]?.affix === Affix.SUFFIX
            ? components[0].axes[0]?.unit
            : "",
        tickprefix:
          components[0].axes[0]?.affix === Affix.PREFIX
            ? components[0].axes[0]?.unit
            : "",
        mirror: true,
        ticks: "inside",
        showline: true,
      },
      yaxis: {
        title: yAxisAttribute + ` [${components[0].axes[1]?.unit}]`,
        type: "log",
        autorange: true,
        ticksuffix:
          components[0].axes[1]?.affix === Affix.SUFFIX
            ? components[0].axes[1]?.unit
            : "",
        tickprefix:
          components[0].axes[1]?.affix === Affix.PREFIX
            ? components[0].axes[1]?.unit
            : "",
        mirror: true,
        ticks: "inside",
        showline: true,
      },
      font: {
        family: "Times New Roman",
        size: 12,
        color: "#000000",
      },
      showlegend: true,
      legend: {
        x: 0.7,
        y: 0.05,
        bordercolor: "#000000",
        borderwidth: 1,
        itemsizing: "constant",
        marker: {
          size: 2,
        },
      },
    };

    layout["title"] = `${xAxisAttribute} vs ${yAxisAttribute}`;
    setPlotLayout(layout);
    return layout;
  };

  return (
    <div className="grid grid-flow-col h-screen">
      <div className="col-span-3 border-r-2 border-black pr-4">
        <div className="px-8 pt-8">
          <Dropdown
            defaultText={"Select X-Axis"}
            options={COLUMNS.filter((column) => {
              return column.type === ColumnType.Attribute;
            }).map((column) => column.name)}
            onSelect={(option) => {
              handleSelectedAttribute(option, Axis.X);
            }}
          />
        </div>
        <div className="px-8 py-4">
          <Dropdown
            defaultText={"Select Y-Axis"}
            options={COLUMNS.filter((column) => {
              return column.type === ColumnType.Attribute;
            }).map((column) => column.name)}
            onSelect={(option) => {
              handleSelectedAttribute(option, Axis.Y);
            }}
          />
        </div>
      </div>
      <div className="col-span-9 h-max">
        <div className="grid grid-cols-3 pt-8 px-6">
          <div className="col-span-1 px-2">
            <Dropdown
              defaultText={"Select Component"}
              options={COLUMNS.filter((column) => {
                return column.type === ColumnType.Category;
              }).map((column) => column.name)}
              onSelect={setSelectedComponent}
            />
          </div>
          <div className="col-span-1 px-2">
            <Dropdown
              defaultText={"Select Year"}
              options={["2022"]}
              onSelect={setSelectedYear}
            />
          </div>
          <div className="col-span-1 px-2">
            <button
              className="w-full bg-blue-500 hover:bg-blue-700 text-white font-bold py-4 px-4"
              onClick={addToPlot}
            >
              Add to Plot
            </button>
          </div>
        </div>
        <div className="flex flex-nowrap pt-5 px-6">
          {plotTraces.map((trace) => {
            return (
              <div className="px-2">
                <PlotTrace trace={trace} onRemove={removeFromPlot} />
              </div>
            );
          })}
        </div>
        <div className="flex justify-center">
          <Plot {...graphProps} className="w-9/12" />
        </div>
        {components && components?.length > 0 && (
          <label>
            Plotting{" "}
            {components
              ?.map((component) => component.axes?.[0].data.length)
              .reduce((a, b) => a + b, 0)
              .toLocaleString("en-US")}{" "}
            components
          </label>
        )}
        <div>
          {plotComponent.map((component, i) => {
            return (
              // set background color to the color of the component
              <div
                style={{
                  backgroundColor: traceColors[component.fullData.index],
                  padding: "1.0em",
                  margin: "0.5em",
                  display: "flex",
                }}
              >
                <div
                  dangerouslySetInnerHTML={{ __html: component.text }}
                  style={{ flex: 1 }}
                />
                <button
                  style={{
                    margin: "0.5em",
                    verticalAlign: "middle",
                  }}
                  type="button"
                  onClick={() => onPlotDeselectPoint(component, i)}
                >
                  Delete
                </button>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
