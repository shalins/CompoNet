/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Affix, affixFromJSON, affixToJSON } from "./componet";

export const protobufPackage = "componet.graph";

export interface Axis {
  name: string;
  shortname: string;
  data: number[];
  affix?: Affix | undefined;
  unit?: string | undefined;
  computed: boolean;
}

export interface Component {
  name: string;
  year: string;
  axes: Axis[];
  mpns: string[];
  manufacturers: string[];
}

export interface Components {
  components: Component[];
}

function createBaseAxis(): Axis {
  return { name: "", shortname: "", data: [], affix: undefined, unit: undefined, computed: false };
}

export const Axis = {
  encode(message: Axis, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.name !== "") {
      writer.uint32(10).string(message.name);
    }
    if (message.shortname !== "") {
      writer.uint32(18).string(message.shortname);
    }
    writer.uint32(26).fork();
    for (const v of message.data) {
      writer.double(v);
    }
    writer.ldelim();
    if (message.affix !== undefined) {
      writer.uint32(32).int32(message.affix);
    }
    if (message.unit !== undefined) {
      writer.uint32(42).string(message.unit);
    }
    if (message.computed === true) {
      writer.uint32(48).bool(message.computed);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Axis {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAxis();
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

          message.shortname = reader.string();
          continue;
        case 3:
          if (tag === 25) {
            message.data.push(reader.double());

            continue;
          }

          if (tag === 26) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.data.push(reader.double());
            }

            continue;
          }

          break;
        case 4:
          if (tag !== 32) {
            break;
          }

          message.affix = reader.int32() as any;
          continue;
        case 5:
          if (tag !== 42) {
            break;
          }

          message.unit = reader.string();
          continue;
        case 6:
          if (tag !== 48) {
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

  fromJSON(object: any): Axis {
    return {
      name: isSet(object.name) ? globalThis.String(object.name) : "",
      shortname: isSet(object.shortname) ? globalThis.String(object.shortname) : "",
      data: globalThis.Array.isArray(object?.data) ? object.data.map((e: any) => globalThis.Number(e)) : [],
      affix: isSet(object.affix) ? affixFromJSON(object.affix) : undefined,
      unit: isSet(object.unit) ? globalThis.String(object.unit) : undefined,
      computed: isSet(object.computed) ? globalThis.Boolean(object.computed) : false,
    };
  },

  toJSON(message: Axis): unknown {
    const obj: any = {};
    if (message.name !== "") {
      obj.name = message.name;
    }
    if (message.shortname !== "") {
      obj.shortname = message.shortname;
    }
    if (message.data?.length) {
      obj.data = message.data;
    }
    if (message.affix !== undefined) {
      obj.affix = affixToJSON(message.affix);
    }
    if (message.unit !== undefined) {
      obj.unit = message.unit;
    }
    if (message.computed === true) {
      obj.computed = message.computed;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Axis>, I>>(base?: I): Axis {
    return Axis.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Axis>, I>>(object: I): Axis {
    const message = createBaseAxis();
    message.name = object.name ?? "";
    message.shortname = object.shortname ?? "";
    message.data = object.data?.map((e) => e) || [];
    message.affix = object.affix ?? undefined;
    message.unit = object.unit ?? undefined;
    message.computed = object.computed ?? false;
    return message;
  },
};

function createBaseComponent(): Component {
  return { name: "", year: "", axes: [], mpns: [], manufacturers: [] };
}

export const Component = {
  encode(message: Component, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.name !== "") {
      writer.uint32(10).string(message.name);
    }
    if (message.year !== "") {
      writer.uint32(18).string(message.year);
    }
    for (const v of message.axes) {
      Axis.encode(v!, writer.uint32(26).fork()).ldelim();
    }
    for (const v of message.mpns) {
      writer.uint32(34).string(v!);
    }
    for (const v of message.manufacturers) {
      writer.uint32(42).string(v!);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Component {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseComponent();
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

          message.year = reader.string();
          continue;
        case 3:
          if (tag !== 26) {
            break;
          }

          message.axes.push(Axis.decode(reader, reader.uint32()));
          continue;
        case 4:
          if (tag !== 34) {
            break;
          }

          message.mpns.push(reader.string());
          continue;
        case 5:
          if (tag !== 42) {
            break;
          }

          message.manufacturers.push(reader.string());
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Component {
    return {
      name: isSet(object.name) ? globalThis.String(object.name) : "",
      year: isSet(object.year) ? globalThis.String(object.year) : "",
      axes: globalThis.Array.isArray(object?.axes) ? object.axes.map((e: any) => Axis.fromJSON(e)) : [],
      mpns: globalThis.Array.isArray(object?.mpns) ? object.mpns.map((e: any) => globalThis.String(e)) : [],
      manufacturers: globalThis.Array.isArray(object?.manufacturers)
        ? object.manufacturers.map((e: any) => globalThis.String(e))
        : [],
    };
  },

  toJSON(message: Component): unknown {
    const obj: any = {};
    if (message.name !== "") {
      obj.name = message.name;
    }
    if (message.year !== "") {
      obj.year = message.year;
    }
    if (message.axes?.length) {
      obj.axes = message.axes.map((e) => Axis.toJSON(e));
    }
    if (message.mpns?.length) {
      obj.mpns = message.mpns;
    }
    if (message.manufacturers?.length) {
      obj.manufacturers = message.manufacturers;
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Component>, I>>(base?: I): Component {
    return Component.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Component>, I>>(object: I): Component {
    const message = createBaseComponent();
    message.name = object.name ?? "";
    message.year = object.year ?? "";
    message.axes = object.axes?.map((e) => Axis.fromPartial(e)) || [];
    message.mpns = object.mpns?.map((e) => e) || [];
    message.manufacturers = object.manufacturers?.map((e) => e) || [];
    return message;
  },
};

function createBaseComponents(): Components {
  return { components: [] };
}

export const Components = {
  encode(message: Components, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    for (const v of message.components) {
      Component.encode(v!, writer.uint32(10).fork()).ldelim();
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Components {
    const reader = input instanceof _m0.Reader ? input : _m0.Reader.create(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseComponents();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if (tag !== 10) {
            break;
          }

          message.components.push(Component.decode(reader, reader.uint32()));
          continue;
      }
      if ((tag & 7) === 4 || tag === 0) {
        break;
      }
      reader.skipType(tag & 7);
    }
    return message;
  },

  fromJSON(object: any): Components {
    return {
      components: globalThis.Array.isArray(object?.components)
        ? object.components.map((e: any) => Component.fromJSON(e))
        : [],
    };
  },

  toJSON(message: Components): unknown {
    const obj: any = {};
    if (message.components?.length) {
      obj.components = message.components.map((e) => Component.toJSON(e));
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Components>, I>>(base?: I): Components {
    return Components.fromPartial(base ?? ({} as any));
  },
  fromPartial<I extends Exact<DeepPartial<Components>, I>>(object: I): Components {
    const message = createBaseComponents();
    message.components = object.components?.map((e) => Component.fromPartial(e)) || [];
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

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}
