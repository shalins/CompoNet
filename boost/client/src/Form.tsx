import { ChangeEvent } from "react";
import Plot from "react-plotly.js";
import { useEffect, useState } from "react";
//import { Component, parse } from "./parse";
//import { ColumnType, columns } from "./utils/octopart";
import { QueryParser } from "componet/componet";
import { Components, Component } from "./proto/ts/componet.graph";
import { ColumnType } from "./proto/ts/componet.metadata";
import { Affix } from "./proto/ts/componet";
import { COLUMNS, ATTRIBUTES, CATEGORIES } from "./utils/octopart";

export default function GraphForm() {
  const [components, setComponents] = useState<Component[]>();

  const [checkedCategories, setCheckedCategories] = useState<number[]>([]);
  const [checkedAttributes, setCheckedAttributes] = useState<string[]>([]);

  const handleOnCategoryChanged = (
    event: ChangeEvent<HTMLInputElement>,
    id: number
  ) => {
    if (event.target.checked) {
      setCheckedCategories((oldCheckedCategories: number[]) => [
        ...oldCheckedCategories,
        id,
      ]);
    } else {
      setCheckedCategories(
        checkedCategories.filter((category) => category !== id)
      );
    }
  };

  const handleOnAttributeChanged = (
    event: ChangeEvent<HTMLInputElement>,
    id: string
  ) => {
    if (event.target.checked) {
      setCheckedAttributes((oldCheckedAttributes: string[]) => [
        ...oldCheckedAttributes,
        id,
      ]);
    } else {
      setCheckedAttributes(
        checkedAttributes.filter((attribute) => attribute !== id)
      );
    }
  };

  useEffect(() => {
    const searchParams = new URLSearchParams();
    if (checkedCategories.length < 1) {
      return;
    }

    if (checkedAttributes.length < 2) {
      return;
    }

    checkedCategories.forEach((id) => {
      searchParams.append("categories", id as unknown as string);
    });

    checkedAttributes.forEach((id) => {
      searchParams.append("attributes", id as unknown as string);
    });

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
        console.log(componentString);
        const components = Components.fromJSON(
          JSON.parse(componentString)
        ).components;

        setComponents(components);
      });
  }, [checkedCategories, checkedAttributes]);

  useEffect(() => {
    console.log(components);
  }, [components]);

  const graphData = (components: Component[]) => {
    const data: any[] = [];

    components.forEach((component) => {
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
        marker: { size: 3 },
      };
      if (component.axes?.length > 2) {
        plotSettings["z"] = component.axes?.[2]?.data;
        plotSettings["type"] = "scatter3d";
      }
      data.push(plotSettings);
    });
    return data;
  };

  const graphLayout = (components: Component[]) => {
    // get the attribute names from the checked attributes.
    //const checkedAttributeNames: string[] = checkedAttributes.map((id) => {
    //  return (
    //    ATTRIBUTES.find((attribute) => {
    //      return attribute.id === id;
    //    })?.name ?? "Undefined"
    //  );
    //});

    const checkedAttributeNames: string[] = checkedAttributes.map((type) => {
      return (
        COLUMNS.find((column) => {
          return column.column === type;
        })?.name ?? "Undefined"
      );
    });

    const layout: { [key: string]: any } = {
      autosize: true,
      xaxis: {
        title: checkedAttributeNames[0] + ` [${components[0].axes[0]?.unit}]`,
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
        title: checkedAttributeNames[1] + ` [${components[0].axes[1]?.unit}]`,
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

    if (checkedAttributeNames.length > 2) {
      layout["zaxis"] = {
        title: checkedAttributeNames[2],
        type: "log",
        autorange: true,
        ticksuffix:
          components[0].axes[2]?.affix === Affix.SUFFIX
            ? components[0].axes[2]?.unit
            : "",
        tickprefix:
          components[0].axes[2]?.affix === Affix.PREFIX
            ? components[0].axes[2]?.unit
            : "",
      };
    }
    layout["title"] = checkedAttributeNames
      .map((name, i) => {
        let title = name;
        if (i !== checkedAttributeNames.length - 1) {
          title += " vs ";
        }
        return title;
      })
      .join("");
    return layout;
  };

  return (
    <>
      <form>
        <div className="row">
          <div className="five columns">
            <label>Component List</label>

            {COLUMNS.filter((column) => {
              return column.type === ColumnType.Category;
            }).map((category) => {
              return (
                <>
                  <input
                    type="checkbox"
                    key={category.column}
                    name="category"
                    value={category.name}
                    onChange={(event) => {
                      if (category.octopartId) {
                        handleOnCategoryChanged(event, category.octopartId);
                      }
                    }}
                  />
                  <label>{category.name}</label>
                </>
              );
            })}
          </div>
          <div className="three columns">
            <label>Attribute List</label>

            {COLUMNS.filter((column) => {
              return column.type === ColumnType.Attribute;
            }).map((attribute) => {
              return (
                <>
                  <input
                    type="checkbox"
                    key={attribute.column}
                    name="attributes"
                    value={attribute.name}
                    onChange={(event) =>
                      handleOnAttributeChanged(event, attribute.column)
                    }
                  />
                  <label>{attribute.name}</label>
                </>
              );
            })}
          </div>
          <div className="three columns">
            <Plot
              data={components ? graphData(components) : []}
              layout={components ? graphLayout(components) : {}}
            />
          </div>
        </div>
      </form>
    </>
  );
}
