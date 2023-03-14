declare module "plotly.js/dist/plotly" {
  export function relayout(plot: any, layout: any): void;
}

declare module "react-plotly.js/factory" {
  export default function plotComponentFactory(Plotly: any): any;
}
