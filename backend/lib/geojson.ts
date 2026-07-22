// GeoJSON & PostGIS WKT/EWKB conversion helper utilities

export interface GeoJSONPolygon {
  type: 'Polygon';
  coordinates: number[][][]; // [[[lng, lat], [lng, lat], ...]]
}

export interface GeoJSONPoint {
  type: 'Point';
  coordinates: number[]; // [lng, lat]
}

export interface GeoJSONFeature<G = GeoJSONPolygon | GeoJSONPoint, P = Record<string, any>> {
  type: 'Feature';
  geometry: G;
  properties: P;
}

/** Convert GeoJSON Polygon to PostGIS ST_GeomFromGeoJSON SQL expression params */
export function geoJsonToPostGISParam(geoJson: GeoJSONPolygon | GeoJSONPoint | string): string {
  if (typeof geoJson === 'string') return geoJson;
  return JSON.stringify(geoJson);
}

/** Validate GeoJSON Polygon basic structure */
export function isValidGeoJSONPolygon(geoJson: any): boolean {
  if (!geoJson || geoJson.type !== 'Polygon' || !Array.isArray(geoJson.coordinates)) {
    return false;
  }
  const ring = geoJson.coordinates[0];
  if (!Array.isArray(ring) || ring.length < 4) {
    return false; // Minimum 4 points for closed polygon (1st == last)
  }
  // Check closed ring
  const first = ring[0];
  const last = ring[ring.length - 1];
  return first[0] === last[0] && first[1] === last[1];
}

/** Validate GeoJSON Point basic structure */
export function isValidGeoJSONPoint(geoJson: any): boolean {
  return (
    geoJson &&
    geoJson.type === 'Point' &&
    Array.isArray(geoJson.coordinates) &&
    geoJson.coordinates.length >= 2 &&
    typeof geoJson.coordinates[0] === 'number' &&
    typeof geoJson.coordinates[1] === 'number'
  );
}
