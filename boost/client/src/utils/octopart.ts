import columns from "../metadata/columns.json";
import categories from "../metadata/categories.json";
import attributes from "../metadata/attributes.json";

import {
  DatabaseMetadata,
  OctopartMetadata,
  Columns,
  Categories,
  Attributes,
} from "../proto/ts/componet.metadata";

export const COLUMNS: DatabaseMetadata[] = Columns.fromJSON(columns).columns;
export const CATEGORIES: OctopartMetadata[] =
  Categories.fromJSON(categories).categories;
export const ATTRIBUTES: OctopartMetadata[] =
  Attributes.fromJSON(attributes).attributes;
