import plotComponentFactory from "react-plotly.js/factory";
import Plotly from "plotly.js/dist/plotly";

import { useEffect, useState } from "react";
import { QueryParser } from "componet/componet";
import { Components, Component } from "../proto/ts/componet.graph";
import { ColumnType } from "../proto/ts/componet.metadata";
import { Affix } from "../proto/ts/componet";
import { COLUMNS } from "../utils/octopart";
import Dropdown from "./Dropdown";
import PlotTrace from "./Trace";
import PlotPoint from "./Point";
import Alert from "./Alert";
import { Trace, Point, Axis } from "../utils/types";
import { DEFAULT_YEAR, YEARS } from "../utils/consts";
import { LegendConstants, MarkerConstants, PlotConstants } from "./plot/consts";
import ExportButton from "./ExportButton";

export default function GraphForm() {
  // Selection Parameters
  const [xAxisAttribute, setXAxisAttribute] = useState<string>();
  const [yAxisAttribute, setYAxisAttribute] = useState<string>();
  const [selectedComponent, setSelectedComponent] = useState<string>();
  const [selectedYear, setSelectedYear] = useState<string>(DEFAULT_YEAR);

  // Data that corresponds to user selections for the plot
  const [plotTraces, setPlotTraces] = useState<Trace[]>([]);
  const [selectedPlotComponents, setSelectedPlotComponents] = useState<Point[]>([]);

  // Actual plot data
  const [plotData, setPlotData] = useState<any[]>([]);
  const [plotLayout, setPlotLayout] = useState<{ [key: string]: any }>({});

  // Raw data from the database
  const [components, setComponents] = useState<Component[]>();

  // Loading data from the database
  const [loading, setLoading] = useState<boolean>(false);

  // Error messages
  const [alertMessage, setAlertMessage] = useState<string>();

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

    const fullDataIdx = event.points[0].fullData.index;
    const ptIdx = event.points[0].pointIndex;
    const mpn = components?.[fullDataIdx].mpns[ptIdx];
    const manufacturer = components?.[fullDataIdx].manufacturers[ptIdx];
    const point: Point = {
      ptIdx,
      fullDataIdx,
      mpn: mpn ?? "",
      color: plotData[fullDataIdx].marker.color[ptIdx],
      manufacturer: manufacturer ?? "",
      link: `https://octopart.com/search?q=${mpn}&view=list`,
      xAxis: components?.[fullDataIdx].axes[0].data[ptIdx],
      yAxis: components?.[fullDataIdx].axes[1].data[ptIdx],
      xUnits: components?.[fullDataIdx].axes[0].unit,
      yUnits: components?.[fullDataIdx].axes[1].unit,
    };
    setSelectedPlotComponents((prev) => [...prev, point]);

    plotData[fullDataIdx].marker.color[ptIdx] = MarkerConstants.selectColor;
    plotData[fullDataIdx].marker.size[ptIdx] = MarkerConstants.selectSize;
    plotData[fullDataIdx].marker.symbol[ptIdx] = MarkerConstants.selectSymbol;
  };

  const onPlotDeselectPoint = (point: Point, i: number) => {
    setSelectedPlotComponents((prev) => {
      plotData[point.fullDataIdx].marker.color[point.ptIdx] = point.color;
      plotData[point.fullDataIdx].marker.size[point.ptIdx] = MarkerConstants.normalSize;
      plotData[point.fullDataIdx].marker.symbol[point.ptIdx] = MarkerConstants.normalSymbol;
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
      color: MarkerConstants.traceColors[plotTraces.length],
      year: selectedYear,
    };

    // Clear the current selections
    setSelectedComponent(undefined);
    setSelectedYear(DEFAULT_YEAR);

    // Avoid duplicate traces
    if (
      plotTraces.some((t) => t.title === trace.title && t.year === trace.year)
    ) {
      setAlertMessage(
        `Already added ${trace.title} (${trace.year}) to the plot`
      );
      return;
    }

    setLoading(true);
    setPlotTraces((prev) => [...prev, trace]);
  };

  const removeFromPlot = (trace: Trace) => {
    setLoading(true);
    setPlotTraces((prev) => {
      const p = prev.filter((t) => t !== trace);
      p.forEach((t, i) => (t.color = MarkerConstants.traceColors[i]));
      return p;
    });

    // Handle the case for zero traces
    if (plotTraces.length === 1) {
      setComponents([]);
      setPlotData([]);
      setPlotLayout({});
      setSelectedPlotComponents([]);
      setLoading(false);
    }

    // Reset the dropdown
    // setSelectedComponent("Select Component");
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
    config: {displaylogo: false},
  };
  const Plot = plotComponentFactory(Plotly);

  useEffect(() => {
    console.log(components);
  }, [components]);

  const graphData = (components: Component[]) => {
    const data: any[] = [];

    components.forEach((component, i) => {
      const hoverText: string[] = component.mpns.map((_, idx) => {
        return `
MPN: <b>${component.mpns[idx]}</b><br>
				Manufacturer: <b>${component.manufacturers[idx]}</b><br>
				Year: <b>${component.year}</b><br>
				`;
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
        name: `${component.name} (${component.year})`
          .replace(" Capacitors", "")
          .replace(" Inductors", ""),
        type: "scattergl",
        mode: "markers",
        marker: {
          color: new Array(component.mpns.length).fill(
            plotTraces.find(
              (t) => t.title === component.name && t.year === component.year
            )?.color ?? MarkerConstants.defaultTraceColor
          ),
          size: new Array(component.mpns.length).fill(MarkerConstants.normalSize),
          symbol: new Array(component.mpns.length).fill(MarkerConstants.normalSymbol),
          line: {
            width: MarkerConstants.borderSize,
          },
          opacity: MarkerConstants.opacity,
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
        automargin: true,
        exponentformat: components[0].axes[0]?.computed ? 'power' : 'B', 
        tickfont: {
          size: PlotConstants.fontSize,
          color: PlotConstants.fontColor,
        },
        ticksuffix:
          components[0].axes[0]?.affix === Affix.SUFFIX && !components[0].axes[0]?.computed
            ? components[0].axes[0]?.unit
            : "",
        tickprefix:
          components[0].axes[0]?.affix === Affix.PREFIX && !components[0].axes[0]?.computed
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
        automargin: true,
        exponentformat: components[0].axes[1]?.computed ? 'power' : 'B', 
        tickfont: {
          size: 12,
          color: PlotConstants.fontColor,
        },
        ticksuffix:
          components[0].axes[1]?.affix === Affix.SUFFIX && !components[0].axes[1]?.computed
            ? components[0].axes[1]?.unit
            : "",
        tickprefix:
          components[0].axes[1]?.affix === Affix.PREFIX && !components[0].axes[1]?.computed
            ? components[0].axes[1]?.unit
            : "",
        mirror: true,
        ticks: "inside",
        showline: true,
      },
      font: {
        family: PlotConstants.fontFamily,
        size: PlotConstants.fontSize,
        color: PlotConstants.fontColor,
      },
      showlegend: true,
      legend: {
        x: LegendConstants.location.x,
        y: LegendConstants.location.y,
        bordercolor: LegendConstants.borderColor,
        borderwidth: LegendConstants.borderWidth,
        itemsizing: "constant",
        marker: {
          size: LegendConstants.markerSize,
        },
      },
    };

    setPlotLayout(layout);
    return layout;
  };

  useEffect(() => {
    const computePlot = () => {
      if (
        !xAxisAttribute ||
        !yAxisAttribute ||
        !plotData ||
        !plotLayout ||
        plotTraces.length === 0
      ) {
        return;
      }

      const searchParams = new URLSearchParams();

      plotTraces.forEach((component) => {
        console.warn("Found octopart id for component: ", component);
        const id = COLUMNS.find((c) => c.name === component.title)?.id;
        if (id) {
          searchParams.append("categories", id as unknown as string);
          searchParams.append("years", component.year);
        } else {
          console.warn("Could not find octopart id for component: ", component);
        }
      });

      if (xAxisAttribute && yAxisAttribute) {
        searchParams.append(
          "attributes",
          COLUMNS.find((c) => c.name === xAxisAttribute)
            ?.column as unknown as string
        );
        searchParams.append(
          "attributes",
          COLUMNS.find((c) => c.name === yAxisAttribute)
            ?.column as unknown as string
        );
      }

      fetch("/api?" + searchParams.toString())
        .then((res) => {
          console.log(res);
          return res.json();
        })
        .then((data) => {
          const componentString = QueryParser.parse(
            JSON.stringify(data),
            YEARS,
          ) as unknown as string;

          // Convert the string to a Component object.
          if (!isEmpty(JSON.parse(componentString))) {
            const components = Components.fromJSON(
              JSON.parse(componentString)
            ).components;

            // Rearrage components to match the axis order, since the API
            // is not guaranteed to return the components in the same order.
            const xAxisIndex = components[0].axes.findIndex(
              (axis) => axis.name === xAxisAttribute
            );
            const yAxisIndex = components[0].axes.findIndex(
              (axis) => axis.name === yAxisAttribute
            );
            if (xAxisIndex !== 0 && yAxisIndex !== 1) {
              components.forEach((component) => {
                const xAxis = component.axes[xAxisIndex];
                const yAxis = component.axes[yAxisIndex];
                component.axes[xAxisIndex] = yAxis;
                component.axes[yAxisIndex] = xAxis;
              });
            }

            setComponents(components);
            graphData(components);
            graphLayout(components);
            setSelectedPlotComponents([]);
          } else {
            const trace = plotTraces.find(
              (t) =>
                !components?.find(
                  (c) => c.name === t.title && c.year === t.year
                )
            );
            if (trace) {
              setAlertMessage(
                `Could not find any data for ${trace.title} (${trace.year}) with the selected parameters.`
              );
              removeFromPlot(trace);
            }
          }
          setLoading(false);
        });
    };

    computePlot();
  }, [plotTraces]);

  return (
    <div className="grid grid-cols-12 grid-flow-col h-main">
      <div className="col-span-3 border-r-2 border-black pr-4">
        <div className="px-8 pt-8">
          <Dropdown
            defaultText={"Select X-Axis"}
            selectedOption={xAxisAttribute}
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
            selectedOption={yAxisAttribute}
            options={COLUMNS.filter((column) => {
              return column.type === ColumnType.Attribute;
            }).map((column) => column.name)}
            onSelect={(option) => {
              handleSelectedAttribute(option, Axis.Y);
            }}
          />
        </div>
      </div>
      <div className="col-span-9">
        <div className="grid grid-cols-3 pt-8 px-6">
          {alertMessage && (
            <div className="col-span-3 px-2 pb-4">
              <Alert
                message={alertMessage}
                onClose={() => setAlertMessage("")}
              />
            </div>
          )}
          <div className="col-span-1 px-2">
            <Dropdown
              defaultText={"Select Component"}
              selectedOption={selectedComponent}
              options={COLUMNS.filter((column) => {
                return column.type === ColumnType.Category;
              }).map((column) => column.name)}
              onSelect={setSelectedComponent}
            />
          </div>
          <div className="col-span-1 px-2">
            <Dropdown
              defaultText={"Select Year"}
              selectedOption={selectedYear}
              options={YEARS}
              onSelect={setSelectedYear}
            />
          </div>
          <div className="col-span-1 px-2">
            <button
              className="w-full bg-founders-rock hover:bg-founders-rock-600 text-white font-bold py-4 px-4"
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
        <div className="flex h-plot w-full">
          <Plot {...graphProps} className="w-4/5 mx-auto" />
          {loading && (
            <div className="absolute flex items-center justify-center inset-0 bg-gray-400 bg-opacity-50">
              <div className="text-white text-2xl font-bold">Loading...</div>
              <div role="status">
                <svg
                  aria-hidden="true"
                  className="w-8 h-8 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600"
                  viewBox="0 0 100 101"
                  fill="none"
                  xmlns="http://www.w3.org/2000/svg"
                >
                  <path
                    d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                    fill="currentColor"
                  />
                  <path
                    d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                    fill="currentFill"
                  />
                </svg>
                <span className="sr-only">Loading...</span>
              </div>
            </div>
          )}
        </div>
        <div className="px-8 py-8">
          {components && components?.length > 0 && (
            <span className="pl-2">
              Plotting{" "}
              {components
                ?.map((component) => component.axes?.[0].data.length)
                .reduce((a, b) => a + b, 0)
                .toLocaleString("en-US")}{" "}
              components
            </span>
          )}
          <div className="flex flex-nowrap pt-6">
            {selectedPlotComponents.map((point, i) => {
              return (
                <div className="px-2">
                  <PlotPoint
                    point={point}
                    onRemove={() => {
                      onPlotDeselectPoint(point, i);
                    }}
                  />
                </div>
              );
            })}
          </div>
          <ExportButton points={selectedPlotComponents} />
        </div>
      </div>
    </div>
  );
}
