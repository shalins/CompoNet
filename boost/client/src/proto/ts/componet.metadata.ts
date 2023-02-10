/* eslint-disable */
import Long from "long";
import _m0 from "protobufjs/minimal";
import { Affix, affixFromJSON, affixToJSON } from "./componet";

export const protobufPackage = "componet.metadata";

export enum ColumnType {
  Category = 0,
  Attribute = 1,
  Other = 2,
  UNRECOGNIZED = -1,
}

export function columnTypeFromJSON(object: any): ColumnType {
  switch (object) {
    case 0:
    case "Category":
      return ColumnType.Category;
    case 1:
    case "Attribute":
      return ColumnType.Attribute;
    case 2:
    case "Other":
      return ColumnType.Other;
    case -1:
    case "UNRECOGNIZED":
    default:
      return ColumnType.UNRECOGNIZED;
  }
}

export function columnTypeToJSON(object: ColumnType): string {
  switch (object) {
    case ColumnType.Category:
      return "Category";
    case ColumnType.Attribute:
      return "Attribute";
    case ColumnType.Other:
      return "Other";
    case ColumnType.UNRECOGNIZED:
    default:
      return "UNRECOGNIZED";
  }
}

export interface DatabaseMetadata {
  name: string;
  column: string;
  type: ColumnType;
  unit?: string | undefined;
  affix?: Affix | undefined;
  octopartId?: number | undefined;
}

export interface OctopartMetadata {
  id: number;
  name: string;
  shortname?: string | undefined;
  units?: string | undefined;
}

export interface Columns {
  columns: DatabaseMetadata[];
}

export interface Categories {
  categories: OctopartMetadata[];
}

export interface Attributes {
  attributes: OctopartMetadata[];
}

function createBaseDatabaseMetadata(): DatabaseMetadata {
  return { name: "", column: "", type: 0, unit: undefined, affix: undefined, octopartId: undefined };
}

export const DatabaseMetadata = {
  encode(message: DatabaseMetadata, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.name !== "") {
      writer.uint32(10).string(message.name);
    }
    if (message.column !== "") {
      writer.uint32(18).string(message.column);
    }
    if (message.type !== 0) {
      writer.uint32(24).int32(message.type);
    }
    if (message.unit !== undefined) {
      writer.uint32(34).string(message.unit);
    }
    if (message.affix !== undefined) {
      writer.uint32(40).int32(message.affix);
    }
    if (message.octopartId !== undefined) {
      writer.uint32(48).int64(message.octopartId);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): DatabaseMetadata {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseDatabaseMetadata();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.name = reader.string();
          break;
        case 2:
          message.column = reader.string();
          break;
        case 3:
          message.type = reader.int32() as any;
          break;
        case 4:
          message.unit = reader.string();
          break;
        case 5:
          message.affix = reader.int32() as any;
          break;
        case 6:
          message.octopartId = longToNumber(reader.int64() as Long);
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): DatabaseMetadata {
    return {
      name: isSet(object.name) ? String(object.name) : "",
      column: isSet(object.column) ? String(object.column) : "",
      type: isSet(object.type) ? columnTypeFromJSON(object.type) : 0,
      unit: isSet(object.unit) ? String(object.unit) : undefined,
      affix: isSet(object.affix) ? affixFromJSON(object.affix) : undefined,
      octopartId: isSet(object.octopartId) ? Number(object.octopartId) : undefined,
    };
  },

  toJSON(message: DatabaseMetadata): unknown {
    const obj: any = {};
    message.name !== undefined && (obj.name = message.name);
    message.column !== undefined && (obj.column = message.column);
    message.type !== undefined && (obj.type = columnTypeToJSON(message.type));
    message.unit !== undefined && (obj.unit = message.unit);
    message.affix !== undefined && (obj.affix = message.affix !== undefined ? affixToJSON(message.affix) : undefined);
    message.octopartId !== undefined && (obj.octopartId = Math.round(message.octopartId));
    return obj;
  },

  create<I extends Exact<DeepPartial<DatabaseMetadata>, I>>(base?: I): DatabaseMetadata {
    return DatabaseMetadata.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<DatabaseMetadata>, I>>(object: I): DatabaseMetadata {
    const message = createBaseDatabaseMetadata();
    message.name = object.name ?? "";
    message.column = object.column ?? "";
    message.type = object.type ?? 0;
    message.unit = object.unit ?? undefined;
    message.affix = object.affix ?? undefined;
    message.octopartId = object.octopartId ?? undefined;
    return message;
  },
};

function createBaseOctopartMetadata(): OctopartMetadata {
  return { id: 0, name: "", shortname: undefined, units: undefined };
}

export const OctopartMetadata = {
  encode(message: OctopartMetadata, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.id !== 0) {
      writer.uint32(8).int64(message.id);
    }
    if (message.name !== "") {
      writer.uint32(18).string(message.name);
    }
    if (message.shortname !== undefined) {
      writer.uint32(26).string(message.shortname);
    }
    if (message.units !== undefined) {
      writer.uint32(34).string(message.units);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): OctopartMetadata {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseOctopartMetadata();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.id = longToNumber(reader.int64() as Long);
          break;
        case 2:
          message.name = reader.string();
          break;
        case 3:
          message.shortname = reader.string();
          break;
        case 4:
          message.units = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): OctopartMetadata {
    return {
      id: isSet(object.id) ? Number(object.id) : 0,
      name: isSet(object.name) ? String(object.name) : "",
      shortname: isSet(object.shortname) ? String(object.shortname) : undefined,
      units: isSet(object.units) ? String(object.units) : undefined,
    };
  },

  toJSON(message: OctopartMetadata): unknown {
    const obj: any = {};
    message.id !== undefined && (obj.id = Math.round(message.id));
    message.name !== undefined && (obj.name = message.name);
    message.shortname !== undefined && (obj.shortname = message.shortname);
    message.units !== undefined && (obj.units = message.units);
    return obj;
  },

  create<I extends Exact<DeepPartial<OctopartMetadata>, I>>(base?: I): OctopartMetadata {
    return OctopartMetadata.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<OctopartMetadata>, I>>(object: I): OctopartMetadata {
    const message = createBaseOctopartMetadata();
    message.id = object.id ?? 0;
    message.name = object.name ?? "";
    message.shortname = object.shortname ?? undefined;
    message.units = object.units ?? undefined;
    return message;
  },
};

function createBaseColumns(): Columns {
  return { columns: [] };
}

export const Columns = {
  encode(message: Columns, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.columns) {
      DatabaseMetadata.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Columns {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseColumns();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.columns.push(DatabaseMetadata.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Columns {
    return {
      columns: Array.isArray(object?.columns) ? object.columns.map((e: any) => DatabaseMetadata.fromJSON(e)) : [],
    };
  },

  toJSON(message: Columns): unknown {
    const obj: any = {};
    if (message.columns) {
      obj.columns = message.columns.map((e) => e ? DatabaseMetadata.toJSON(e) : undefined);
    } else {
      obj.columns = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Columns>, I>>(base?: I): Columns {
    return Columns.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Columns>, I>>(object: I): Columns {
    const message = createBaseColumns();
    message.columns = object.columns?.map((e) => DatabaseMetadata.fromPartial(e)) || [];
    return message;
  },
};

function createBaseCategories(): Categories {
  return { categories: [] };
}

export const Categories = {
  encode(message: Categories, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.categories) {
      OctopartMetadata.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Categories {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseCategories();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.categories.push(OctopartMetadata.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Categories {
    return {
      categories: Array.isArray(object?.categories)
        ? object.categories.map((e: any) => OctopartMetadata.fromJSON(e))
        : [],
    };
  },

  toJSON(message: Categories): unknown {
    const obj: any = {};
    if (message.categories) {
      obj.categories = message.categories.map((e) => e ? OctopartMetadata.toJSON(e) : undefined);
    } else {
      obj.categories = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Categories>, I>>(base?: I): Categories {
    return Categories.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Categories>, I>>(object: I): Categories {
    const message = createBaseCategories();
    message.categories = object.categories?.map((e) => OctopartMetadata.fromPartial(e)) || [];
    return message;
  },
};

function createBaseAttributes(): Attributes {
  return { attributes: [] };
}

export const Attributes = {
  encode(message: Attributes, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.attributes) {
      OctopartMetadata.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Attributes {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAttributes();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.attributes.push(OctopartMetadata.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Attributes {
    return {
      attributes: Array.isArray(object?.attributes)
        ? object.attributes.map((e: any) => OctopartMetadata.fromJSON(e))
        : [],
    };
  },

  toJSON(message: Attributes): unknown {
    const obj: any = {};
    if (message.attributes) {
      obj.attributes = message.attributes.map((e) => e ? OctopartMetadata.toJSON(e) : undefined);
    } else {
      obj.attributes = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Attributes>, I>>(base?: I): Attributes {
    return Attributes.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Attributes>, I>>(object: I): Attributes {
    const message = createBaseAttributes();
    message.attributes = object.attributes?.map((e) => OctopartMetadata.fromPartial(e)) || [];
    return message;
  },
};

declare var self: any | undefined;
declare var window: any | undefined;
declare var global: any | undefined;
var tsProtoGlobalThis: any = (() => {
  if (typeof globalThis !== "undefined") {
    return globalThis;
  }
  if (typeof self !== "undefined") {
    return self;
  }
  if (typeof window !== "undefined") {
    return window;
  }
  if (typeof global !== "undefined") {
    return global;
  }
  throw "Unable to locate global object";
})();

type Builtin = Date | Function | Uint8Array | string | number | boolean | undefined;

export type DeepPartial<T> = T extends Builtin ? T
  : T extends Array<infer U> ? Array<DeepPartial<U>> : T extends ReadonlyArray<infer U> ? ReadonlyArray<DeepPartial<U>>
  : T extends {} ? { [K in keyof T]?: DeepPartial<T[K]> }
  : Partial<T>;

type KeysOfUnion<T> = T extends T ? keyof T : never;
export type Exact<P, I extends P> = P extends Builtin ? P
  : P & { [K in keyof P]: Exact<P[K], I[K]> } & { [K in Exclude<keyof I, KeysOfUnion<P>>]: never };

function longToNumber(long: Long): number {
  if (long.gt(Number.MAX_SAFE_INTEGER)) {
    throw new tsProtoGlobalThis.Error("Value is larger than Number.MAX_SAFE_INTEGER");
  }
  return long.toNumber();
}

if (_m0.util.Long !== Long) {
  _m0.util.Long = Long as any;
  _m0.configure();
}

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
