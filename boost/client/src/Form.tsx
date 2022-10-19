import { ChangeEvent } from "react";
import Plot from "react-plotly.js";
import { useEffect, useState } from "react";
import { Component, parse } from "./parse";
import { categories, attributes, ComponentSpec } from "./utils/octopart";

export default function GraphForm() {
  const [components, setComponents] = useState<Component[]>();

  const [checkedCategories, setCheckedCategories] = useState<string[]>([]);
  const [checkedAttributes, setCheckedAttributes] = useState<string[]>([]);

  const handleOnCategoryChanged = (
    event: ChangeEvent<HTMLInputElement>,
    id: string
  ) => {
    if (event.target.checked) {
      setCheckedCategories((oldCheckedCategories: string[]) => [
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
      searchParams.append("categories", id);
    });

    checkedAttributes.forEach((id) => {
      searchParams.append("attributes", id);
    });

    fetch("/api?" + searchParams.toString())
      .then((res) => res.json())
      .then((data) => {
        const components = parse(data);
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
				Manufacturer: <b>${component.manufacturerNames[idx]}</b>`;
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
    const checkedAttributeNames: string[] = checkedAttributes.map((id) => {
      return (
        attributes.find((attribute) => {
          return attribute.id === id;
        })?.name ?? "Undefined"
      );
    });

    const layout: { [key: string]: any } = {
      autosize: true,
      xaxis: {
        title:
          checkedAttributeNames[0] +
          ` [${components[0].axes[0]?.suffix ?? "#"}]`,
        type: "log",
        autorange: true,
        ticksuffix: components[0].axes[0]?.suffix ?? "",
        mirror: true,
        ticks: "inside",
        showline: true,
      },
      yaxis: {
        title:
          checkedAttributeNames[1] +
          ` [${components[0].axes[1]?.suffix ?? "#"}]`,
        type: "log",
        autorange: true,
        ticksuffix: components[0].axes[1]?.suffix ?? "",
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
        ticksuffix: components[0].axes[2]?.suffix ?? "",
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

            {categories.map((category) => {
              return (
                <>
                  <input
                    type="checkbox"
                    key={category.id}
                    name="category"
                    value={category.name}
                    onChange={(event) =>
                      handleOnCategoryChanged(event, category.id)
                    }
                  />
                  <label>{category.name}</label>
                </>
              );
            })}
          </div>
          <div className="three columns">
            <label>Attribute List</label>
            {attributes.map((attribute) => {
              return (
                <>
                  <input
                    type="checkbox"
                    key={attribute.id}
                    name="attributes"
                    value={attribute.name}
                    onChange={(event) =>
                      handleOnAttributeChanged(event, attribute.id)
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
