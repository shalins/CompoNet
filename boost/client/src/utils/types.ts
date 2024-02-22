export enum Axis {
  X = "x",
  Y = "y",
}

export type Trace = {
  title: string;
  color: string;
  year: string;
};

export type Point = {
  ptIdx: number;
  fullDataIdx: number;
  mpn: string;
  color: string;
  manufacturer: string;
  link: string;
  xAxis?: number;
  yAxis?: number;
  xUnits?: string;
  yUnits?: string;
};
