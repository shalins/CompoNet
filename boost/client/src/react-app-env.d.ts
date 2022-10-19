declare module "react-plotly.js" {
  import * as Plotly from "plotly.js";
  import { PureComponent } from "react";

  export interface PlotParams {
    config?: Plotly.Config;
    data: Plotly.Data[];
    layout: Partial<Plotly.Layout>;
    onClickAnnotation?: (event: Plotly.ClickAnnotationEvent) => void;
  }

  export default class Plot extends PureComponent<PlotParams> {}
}
