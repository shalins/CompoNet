import { attributes } from "./octopart";

export const generateQuery = (categoryId: string, attributeIds: string[]) => {
  // We want to geenrate a SQL query that selects attributes that we wanted
  // from all the different categories that we want.

  // Convert all the attrbiute ids to shortnames.
  const queryAttributes = attributeIds.map((id) => {
    return attributes.find((attribute) => attribute.id === id)?.shortname;
  });

  // Then generate the query.
  let query = "SELECT ";

  // Grab the manufacturer part number.
  query += "part_mpn, ";

  // Grab the manufacturer name.
  query += "part_manufacturer_name, ";

  // Add the attributes to the query.
  queryAttributes.forEach((attribute, idx) => {
    query += `part_specs_${attribute}_display_value`;
    if (idx !== queryAttributes.length - 1) {
      query += ", ";
    }
  });

  query += ` FROM public.all WHERE part_category_id='${categoryId}' AND `;

  // Go through the attributes and add the conditions.
  queryAttributes.forEach((attribute, idx) => {
    query += `part_specs_${attribute}_display_value IS NOT NULL AND `;
    query += `part_specs_${attribute}_display_value != 'nan' `;
    if (idx !== queryAttributes.length - 1) {
      query += " AND ";
    }
  });

  query += ";";

  console.log(query);

  return query;
};
