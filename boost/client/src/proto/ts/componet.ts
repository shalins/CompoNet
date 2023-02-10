/* eslint-disable */

export const protobufPackage = "componet";

export enum Affix {
  PREFIX = 0,
  SUFFIX = 1,
  UNRECOGNIZED = -1,
}

export function affixFromJSON(object: any): Affix {
  switch (object) {
    case 0:
    case "PREFIX":
      return Affix.PREFIX;
    case 1:
    case "SUFFIX":
      return Affix.SUFFIX;
    case -1:
    case "UNRECOGNIZED":
    default:
      return Affix.UNRECOGNIZED;
  }
}

export function affixToJSON(object: Affix): string {
  switch (object) {
    case Affix.PREFIX:
      return "PREFIX";
    case Affix.SUFFIX:
      return "SUFFIX";
    case Affix.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}
