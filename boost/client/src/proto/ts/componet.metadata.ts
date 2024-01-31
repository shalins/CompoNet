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
  id?: number | undefined;
  included: boolean;
  computed?: boolean | undefined;
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
  return {
    name: "",
    column: "",
    type: 0,
    unit: undefined,
    affix: undefined,
    id: undefined,
    included: false,
    computed: undefined,
  };
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
    if (message.id !== undefined) {
      writer.uint32(48).int64(message.id);
    }
    if (message.included === true) {
      writer.uint32(56).bool(message.included);
    }
    if (message.computed !== undefined) {
      writer.uint32(64).bool(message.computed);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): DatabaseMetadata {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseDatabaseMetadata();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.name = reader.string();
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.column = reader.string();
          continue;
        case 3:
          if (tag !== 24) {
            break;
          }

          message.type = reader.int32() as any;
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.unit = reader.string();
          continue;
        case 5:
          if (tag !== 40) {
            break;
          }

          message.affix = reader.int32() as any;
          continue;
        case 6:
          if (tag !== 48) {
            break;
          }

          message.id = longToNumber(reader.int64() as Long);
          continue;
        case 7:
          if (tag !== 56) {
            break;
          }

          message.included = reader.bool();
          continue;
        case 8:
          if (tag !== 64) {
            break;
          }

          message.computed = reader.bool();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): DatabaseMetadata {
    return {
      name: isSet(object.name) ? globalThis.String(object.name) : "",
      column: isSet(object.column) ? globalThis.String(object.column) : "",
      type: isSet(object.type) ? columnTypeFromJSON(object.type) : 0,
      unit: isSet(object.unit) ? globalThis.String(object.unit) : undefined,
      affix: isSet(object.affix) ? affixFromJSON(object.affix) : undefined,
      id: isSet(object.id) ? globalThis.Number(object.id) : undefined,
      included: isSet(object.included) ? globalThis.Boolean(object.included) : false,
      computed: isSet(object.computed) ? globalThis.Boolean(object.computed) : undefined,
    };
  },

  toJSON(message: DatabaseMetadata): unknown {
    const obj: any = {};
    if (message.name !== "") {
      obj.name = message.name;
    }
    if (message.column !== "") {
      obj.column = message.column;
    }
    if (message.type !== 0) {
      obj.type = columnTypeToJSON(message.type);
    }
    if (message.unit !== undefined) {
      obj.unit = message.unit;
    }
    if (message.affix !== undefined) {
      obj.affix = affixToJSON(message.affix);
    }
    if (message.id !== undefined) {
      obj.id = Math.round(message.id);
    }
    if (message.included === true) {
      obj.included = message.included;
    }
    if (message.computed !== undefined) {
      obj.computed = message.computed;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<DatabaseMetadata>, I>>(base?: I): DatabaseMetadata {
    return DatabaseMetadata.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<DatabaseMetadata>, I>>(object: I): DatabaseMetadata {
    const message = createBaseDatabaseMetadata();
    message.name = object.name ?? "";
    message.column = object.column ?? "";
    message.type = object.type ?? 0;
    message.unit = object.unit ?? undefined;
    message.affix = object.affix ?? undefined;
    message.id = object.id ?? undefined;
    message.included = object.included ?? false;
    message.computed = object.computed ?? undefined;
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
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseOctopartMetadata();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 8) {
            break;
          }

          message.id = longToNumber(reader.int64() as Long);
          continue;
        case 2:
          if (tag !== 18) {
            break;
          }

          message.name = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.shortname = reader.string();
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.units = reader.string();
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): OctopartMetadata {
    return {
      id: isSet(object.id) ? globalThis.Number(object.id) : 0,
      name: isSet(object.name) ? globalThis.String(object.name) : "",
      shortname: isSet(object.shortname) ? globalThis.String(object.shortname) : undefined,
      units: isSet(object.units) ? globalThis.String(object.units) : undefined,
    };
  },

  toJSON(message: OctopartMetadata): unknown {
    const obj: any = {};
    if (message.id !== 0) {
      obj.id = Math.round(message.id);
    }
    if (message.name !== "") {
      obj.name = message.name;
    }
    if (message.shortname !== undefined) {
      obj.shortname = message.shortname;
    }
    if (message.units !== undefined) {
      obj.units = message.units;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<OctopartMetadata>, I>>(base?: I): OctopartMetadata {
    return OctopartMetadata.fromPartial(base ?? ({} as any));
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
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseColumns();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.columns.push(DatabaseMetadata.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Columns {
    return {
      columns: globalThis.Array.isArray(object?.columns)
        ? object.columns.map((e: any) => DatabaseMetadata.fromJSON(e))
        : [],
    };
  },

  toJSON(message: Columns): unknown {
    const obj: any = {};
    if (message.columns?.length) {
      obj.columns = message.columns.map((e) => DatabaseMetadata.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Columns>, I>>(base?: I): Columns {
    return Columns.fromPartial(base ?? ({} as any));
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
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseCategories();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.categories.push(OctopartMetadata.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Categories {
    return {
      categories: globalThis.Array.isArray(object?.categories)
        ? object.categories.map((e: any) => OctopartMetadata.fromJSON(e))
        : [],
    };
  },

  toJSON(message: Categories): unknown {
    const obj: any = {};
    if (message.categories?.length) {
      obj.categories = message.categories.map((e) => OctopartMetadata.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Categories>, I>>(base?: I): Categories {
    return Categories.fromPartial(base ?? ({} as any));
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
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAttributes();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.attributes.push(OctopartMetadata.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Attributes {
    return {
      attributes: globalThis.Array.isArray(object?.attributes)
        ? object.attributes.map((e: any) => OctopartMetadata.fromJSON(e))
        : [],
    };
  },

  toJSON(message: Attributes): unknown {
    const obj: any = {};
    if (message.attributes?.length) {
      obj.attributes = message.attributes.map((e) => OctopartMetadata.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Attributes>, I>>(base?: I): Attributes {
    return Attributes.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Attributes>, I>>(object: I): Attributes {
    const message = createBaseAttributes();
    message.attributes = object.attributes?.map((e) => OctopartMetadata.fromPartial(e)) || [];
    return message;
  },
};

type Builtin = Date | Function | Uint8Array | string | number | boolean | undefined;

export type DeepPartial<T> = T extends Builtin ? T
  : T extends globalThis.Array<infer U> ? globalThis.Array<DeepPartial<U>>
  : T extends ReadonlyArray<infer U> ? ReadonlyArray<DeepPartial<U>>
  : T extends {} ? { [K in keyof T]?: DeepPartial<T[K]> }
  : Partial<T>;

type KeysOfUnion<T> = T extends T ? keyof T : never;
export type Exact<P, I extends P> = P extends Builtin ? P
  : P & { [K in keyof P]: Exact<P[K], I[K]> } & { [K in Exclude<keyof I, KeysOfUnion<P>>]: never };

function longToNumber(long: Long): number {
  if (long.gt(globalThis.Number.MAX_SAFE_INTEGER)) {
    throw new globalThis.Error("Value is larger than Number.MAX_SAFE_INTEGER");
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
