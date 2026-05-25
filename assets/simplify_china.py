#!/usr/bin/env python3
"""Simplify China boundary GeoJSON and generate Dart code."""

import json
import math
import sys

def perpendicular_distance(point, line_start, line_end):
    """Distance from point to line segment."""
    if line_start == line_end:
        dx = point[0] - line_start[0]
        dy = point[1] - line_start[1]
        return math.sqrt(dx*dx + dy*dy)

    lx = line_end[0] - line_start[0]
    ly = line_end[1] - line_start[1]

    if lx == 0 and ly == 0:
        dx = point[0] - line_start[0]
        dy = point[1] - line_start[1]
        return math.sqrt(dx*dx + dy*dy)

    t = ((point[0] - line_start[0]) * lx + (point[1] - line_start[1]) * ly) / (lx*lx + ly*ly)
    t = max(0.0, min(1.0, t))

    proj_x = line_start[0] + t * lx
    proj_y = line_start[1] + t * ly

    dx = point[0] - proj_x
    dy = point[1] - proj_y
    return math.sqrt(dx*dx + dy*dy)

def douglas_peucker(points, epsilon):
    """Simplify a polyline using Douglas-Peucker algorithm."""
    if len(points) <= 2:
        return points

    # Find the point with maximum distance
    max_dist = 0
    max_idx = 0
    end = len(points) - 1

    for i in range(1, end):
        dist = perpendicular_distance(points[i], points[0], points[end])
        if dist > max_dist:
            max_dist = dist
            max_idx = i

    if max_dist < epsilon:
        return [points[0], points[end]]

    # Recursive simplification
    left = douglas_peucker(points[:max_idx + 1], epsilon)
    right = douglas_peucker(points[max_idx:], epsilon)

    return left[:-1] + right

def simplify_ring(ring, epsilon):
    """Simplify a closed polygon ring."""
    if len(ring) <= 4:
        return ring
    # Remove last point (closing point) for simplification
    simplified = douglas_peucker(ring[:-1], epsilon) if len(ring) > 1 else ring
    # Ensure closed
    if len(simplified) > 0 and simplified[0] != simplified[-1]:
        simplified.append(simplified[0][:])
    return simplified

def count_points(polygons):
    """Count total coordinate pairs in polygon structure."""
    total = 0
    for poly in polygons:
        for ring in poly:
            total += len(ring)
    return total

def format_dart_list(points):
    """Format a list of [lat, lng] pairs as Dart code."""
    lines = []
    for i in range(0, len(points), 8):
        batch = points[i:i+8]
        items = [f'[{p[0]:.4f},{p[1]:.4f}]' for p in batch]
        if i == 0:
            lines.append('      ' + ','.join(items))
        else:
            lines.append('      ' + ','.join(items))
    return ',\n'.join(lines)

def main():
    with open('D:/xin_qing_ri_ji/assets/china_national.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    feature = data['features'][0]
    geom = feature['geometry']
    all_coords = geom['coordinates']

    print(f'Geometry type: {geom["type"]}')
    print(f'Number of polygons: {len(all_coords)}')
    total_before = count_points(all_coords)
    print(f'Total points before simplification: {total_before}')

    # Epsilon for Douglas-Peucker (degrees). 0.05° ≈ 5.5km
    # Smaller = more detail, larger = more simplification
    EPSILON = 0.02  # high precision for smooth boundary

    # Process each polygon ring
    simplified_coords = []
    for poly in all_coords:
        new_poly = []
        for ring in poly:
            new_ring = simplify_ring(ring, EPSILON)
            new_poly.append(new_ring)
        simplified_coords.append(new_poly)

    total_after = count_points(simplified_coords)
    print(f'Total points after simplification (epsilon={EPSILON}): {total_after}')
    print(f'Reduction: {100 - total_after*100//total_before}%')

    # Identify mainland (largest polygon), Taiwan, Hainan
    # Sort polygons by area (approximated by number of points)
    polygons_with_info = []
    for i, poly in enumerate(simplified_coords):
        if len(poly) > 0 and len(poly[0]) > 0:
            ring = poly[0]  # Outer ring
            # Calculate approximate center
            avg_lat = sum(p[1] for p in ring) / len(ring)
            avg_lng = sum(p[0] for p in ring) / len(ring)
            polygons_with_info.append({
                'index': i,
                'points': len(ring),
                'center_lat': avg_lat,
                'center_lng': avg_lng,
                'rings': poly,
            })

    polygons_with_info.sort(key=lambda x: x['points'], reverse=True)

    print('\nPolygons by size:')
    for p in polygons_with_info[:10]:
        print(f"  #{p['index']}: {p['points']} pts, center ~({p['center_lat']:.1f}, {p['center_lng']:.1f})")

    # Mainland is the largest
    mainland = polygons_with_info[0]

    # Taiwan: center ~(23.5, 121.0)
    taiwan = None
    hainan = None
    for p in polygons_with_info:
        if p['center_lng'] > 119 and p['center_lng'] < 123 and p['center_lat'] > 21 and p['center_lat'] < 26:
            if taiwan is None or p['points'] > taiwan['points']:
                taiwan = p
        if p['center_lng'] > 108 and p['center_lng'] < 111 and p['center_lat'] > 18 and p['center_lat'] < 21:
            if hainan is None or p['points'] > hainan['points']:
                hainan = p

    print(f'\nMainland: polygon #{mainland["index"]}, {mainland["points"]} pts')
    if taiwan:
        print(f'Taiwan: polygon #{taiwan["index"]}, {taiwan["points"]} pts')
    if hainan:
        print(f'Hainan: polygon #{hainan["index"]}, {hainan["points"]} pts')

    # Extract outer rings for mainland, Taiwan, Hainan
    # For mainland, we take the outer ring (first ring of the polygon)
    mainland_ring = mainland['rings'][0]  # Outer ring
    # Convert from [lng, lat] to [lat, lng] format for our _geoToScreen
    mainland_pts = [[p[1], p[0]] for p in mainland_ring]

    tw_pts = []
    if taiwan:
        tw_ring = taiwan['rings'][0]
        tw_pts = [[p[1], p[0]] for p in tw_ring]

    hn_pts = []
    if hainan:
        hn_ring = hainan['rings'][0]
        hn_pts = [[p[1], p[0]] for p in hn_ring]

    # Generate Dart code
    dart_code = '''// Auto-generated simplified China boundary from DataV GeoJSON
// Simplified with Douglas-Peucker (epsilon={epsilon})
// {total_before} → {total_after} coordinate pairs

const List<List<double>> chinaMainland = [
{mainland}
];

const List<List<double>> chinaTaiwan = [
{taiwan}
];

const List<List<double>> chinaHainan = [
{hainan}
];
'''.format(
        epsilon=EPSILON,
        total_before=total_before,
        total_after=total_after,
        mainland=format_dart_list(mainland_pts),
        taiwan=format_dart_list(tw_pts) if tw_pts else '  // (empty)',
        hainan=format_dart_list(hn_pts) if hn_pts else '  // (empty)',
    )

    with open('D:/xin_qing_ri_ji/lib/constants/china_boundary.dart', 'w', encoding='utf-8') as f:
        f.write(dart_code)

    print(f'\nDart code written to lib/constants/china_boundary.dart')
    print(f'Mainland: {len(mainland_pts)} pts, Taiwan: {len(tw_pts)} pts, Hainan: {len(hn_pts)} pts')

if __name__ == '__main__':
    main()
