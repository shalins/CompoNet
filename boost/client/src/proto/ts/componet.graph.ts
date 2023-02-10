/* eslint-disable */
import _m0 from "protobufjs/minimal";
import { Affix, affixFromJSON, affixToJSON } from "./componet";

export const protobufPackage = "componet.graph";

export interface Axis {
  data: number[];
  affix?: Affix | undefined;
  unit?: string | undefined;
}

export interface Component {
  category: string;
  axes: Axis[];
  mpns: string[];
  manufacturers: string[];
}

export interface Components {
  components: Component[];
}

function createBaseAxis(): Axis {
  return { data: [], affix: undefined, unit: undefined };
}

export const Axis = {
  encode(message: Axis, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    writer.uint32(10).fork();
    for (const v of message.data) {
      writer.double(v);
    }
    writer.ldelim();
    if (message.affix !== undefined) {
      writer.uint32(16).int32(message.affix);
    }
    if (message.unit !== undefined) {
      writer.uint32(26).string(message.unit);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Axis {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseAxis();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          if ((tag & 7) === 2) {
            const end2 = reader.uint32() + reader.pos;
            while (reader.pos < end2) {
              message.data.push(reader.double());
            }
          } else {
            message.data.push(reader.double());
          }
          break;
        case 2:
          message.affix = reader.int32() as any;
          break;
        case 3:
          message.unit = reader.string();
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Axis {
    return {
      data: Array.isArray(object?.data) ? object.data.map((e: any) => Number(e)) : [],
      affix: isSet(object.affix) ? affixFromJSON(object.affix) : undefined,
      unit: isSet(object.unit) ? String(object.unit) : undefined,
    };
  },

  toJSON(message: Axis): unknown {
    const obj: any = {};
    if (message.data) {
      obj.data = message.data.map((e) => e);
    } else {
      obj.data = [];
    }
    message.affix !== undefined && (obj.affix = message.affix !== undefined ? affixToJSON(message.affix) : undefined);
    message.unit !== undefined && (obj.unit = message.unit);
    return obj;
  },

  create<I extends Exact<DeepPartial<Axis>, I>>(base?: I): Axis {
    return Axis.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Axis>, I>>(object: I): Axis {
    const message = createBaseAxis();
    message.data = object.data?.map((e) => e) || [];
    message.affix = object.affix ?? undefined;
    message.unit = object.unit ?? undefined;
    return message;
  },
};

function createBaseComponent(): Component {
  return { category: "", axes: [], mpns: [], manufacturers: [] };
}

export const Component = {
  encode(message: Component, writer: _m0.Writer = _m0.Writer.create()): _m0.Writer {
    if (message.category !== "") {
      writer.uint32(10).string(message.category);
    }
    for (const v of message.axes) {
      Axis.encode(v!, writer.uint32(18).fork()).ldelim();
    }
    for (const v of message.mpns) {
      writer.uint32(26).string(v!);
    }
    for (const v of message.manufacturers) {
      writer.uint32(34).string(v!);
    }
    return writer;
  },

  decode(input: _m0.Reader | Uint8Array, length?: number): Component {
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseComponent();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.category = reader.string();
          break;
        case 2:
          message.axes.push(Axis.decode(reader, reader.uint32()));
          break;
        case 3:
          message.mpns.push(reader.string());
          break;
        case 4:
          message.manufacturers.push(reader.string());
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Component {
    return {
      category: isSet(object.category) ? String(object.category) : "",
      axes: Array.isArray(object?.axes) ? object.axes.map((e: any) => Axis.fromJSON(e)) : [],
      mpns: Array.isArray(object?.mpns) ? object.mpns.map((e: any) => String(e)) : [],
      manufacturers: Array.isArray(object?.manufacturers) ? object.manufacturers.map((e: any) => String(e)) : [],
    };
  },

  toJSON(message: Component): unknown {
    const obj: any = {};
    message.category !== undefined && (obj.category = message.category);
    if (message.axes) {
      obj.axes = message.axes.map((e) => e ? Axis.toJSON(e) : undefined);
    } else {
      obj.axes = [];
    }
    if (message.mpns) {
      obj.mpns = message.mpns.map((e) => e);
    } else {
      obj.mpns = [];
    }
    if (message.manufacturers) {
      obj.manufacturers = message.manufacturers.map((e) => e);
    } else {
      obj.manufacturers = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Component>, I>>(base?: I): Component {
    return Component.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Component>, I>>(object: I): Component {
    const message = createBaseComponent();
    message.category = object.category ?? "";
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
    const reader = input instanceof _m0.Reader ? input : new _m0.Reader(input);
    let end = length === undefined ? reader.len : reader.pos + length;
    const message = createBaseComponents();
    while (reader.pos < end) {
      const tag = reader.uint32();
      switch (tag >>> 3) {
        case 1:
          message.components.push(Component.decode(reader, reader.uint32()));
          break;
        default:
          reader.skipType(tag & 7);
          break;
      }
    }
    return message;
  },

  fromJSON(object: any): Components {
    return {
      components: Array.isArray(object?.components) ? object.components.map((e: any) => Component.fromJSON(e)) : [],
    };
  },

  toJSON(message: Components): unknown {
    const obj: any = {};
    if (message.components) {
      obj.components = message.components.map((e) => e ? Component.toJSON(e) : undefined);
    } else {
      obj.components = [];
    }
    return obj;
  },

  create<I extends Exact<DeepPartial<Components>, I>>(base?: I): Components {
    return Components.fromPartial(base ?? {});
  },

  fromPartial<I extends Exact<DeepPartial<Components>, I>>(object: I): Components {
    const message = createBaseComponents();
    message.components = object.components?.map((e) => Component.fromPartial(e)) || [];
    return message;
  },
};

type Builtin = Date | Function | Uint8Array | string | number | boolean | undefined;

export type DeepPartial<T> = T extends Builtin ? T
  : T extends Array<infer U> ? Array<DeepPartial<U>> : T extends ReadonlyArray<infer U> ? ReadonlyArray<DeepPartial<U>>
  : T extends {} ? { [K in keyof T]?: DeepPartial<T[K]> }
  : Partial<T>;

type KeysOfUnion<T> = T extends T ? keyof T : never;
export type Exact<P, I extends P> = P extends Builtin ? P
  : P & { [K in keyof P]: Exact<P[K], I[K]> } & { [K in Exclude<keyof I, KeysOfUnion<P>>]: never };

function isSet(value: any): boolean {
  return value !== null && value !== undefined;
}