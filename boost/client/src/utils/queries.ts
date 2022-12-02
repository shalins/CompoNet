import { attributes } from "./octopart";

// We want to geenrate a SQL query that selects attributes that we wanted
// from all the different categories that we want.
export const generateQuery = (categoryId: string, attributeIds: string[]) => {
  // Convert all the attrbiute ids to shortnames.
  const queryAttributes = attributeIds.map((id) => {
    return attributes.find((attribute) => attribute.id === id)?.shortname;
  });

  // Then generate the query.
  let query = "SELECT ";

  // Grab the manufacturer part number and manufacturer name.
  query += "part_mpn, part_manufacturer_name, ";

  // Add the attributes to the query.
  queryAttributes.forEach((attribute, idx) => {
    // Attributes with negative IDs are custom ones that we've defined,
    // (not ones that are part of the Octopart API). We handle them by
    // querying the entire shortname.
    if (attributeIds[idx].includes("-")) {
      console.log(attributeIds[idx], attribute);
      query += attribute;
    } else {
      query += `part_specs_${attribute}_display_value`;
    }
    if (idx !== queryAttributes.length - 1) {
      query += ", ";
    }
  });

  query += ` FROM public.all WHERE part_category_id='${categoryId}' AND `;

  // Go through the attributes and add the conditions.
  queryAttributes.forEach((attribute, idx) => {
    if (attributeIds[idx].includes("-")) {
      query += `${attribute} IS NOT NULL AND `;
      query += `${attribute} != 'nan' `;
    } else {
      query += `part_specs_${attribute}_display_value IS NOT NULL AND `;
      query += `part_specs_${attribute}_display_value != 'nan' `;
    }
    if (idx !== queryAttributes.length - 1) {
      query += " AND ";
    }
  });

  query += ";";

  console.log(query);

  return query;
};
