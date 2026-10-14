"""Builds an annotated documentation image from a screenshot and a JSON spec.

usage: python annotate.py specs/<name>.json

Spec format (all coordinates in screenshot pixels):
{
  "image":  "raw/<name>.png",                         # relative to tools/screenshots
  "output": "AcquisitionSettings/images/<name>.drawio", # relative to the repository root
  "callouts": [{"n": 1, "circle": [x, y], "target": [x, y]}],  # circle = top-left of the 50x50 circle;
                                                       # "targets": [[x, y], ...] for several lines
  "areas":    [{"rect": [x, y, w, h]}],                # dashed frames, e.g. the main parts of a window
  "paths":    [{"points": [[x, y], [x, y], ...]}]      # dashed curves with dots at both ends, e.g. drag and drop
}

With callouts or areas the output must be a .drawio file - it is written uncompressed and the caller
exports it to a PNG of the same name (see Build-ShotAnnotation in ShotLib.ps1). Without them the
output is a .png and the screenshot is copied as it is. The path of the written file is printed last.
"""
import base64
import json
import os
import shutil
import struct
import sys
from xml.sax.saxutils import quoteattr

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))

YELLOW = '#FFFF00'
CIRCLE_SIZE = 50
CIRCLE_STYLE = ('ellipse;whiteSpace=wrap;html=1;aspect=fixed;fontSize=42;fontColor=#FFFF00;strokeColor=#FFFF00;'
                'strokeWidth=8;fillColor=#000000;')
EDGE_STYLE = 'endArrow=oval;html=1;rounded=0;strokeWidth=6;strokeColor=#FFFF00;endFill=1;'
AREA_STYLE = 'rounded=0;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#FFFF00;strokeWidth=4;dashed=1;dashPattern=3 2;'
PATH_STYLE = ('curved=1;html=1;strokeWidth=4;strokeColor=#FFFF00;dashed=1;dashPattern=3 2;'
              'startArrow=oval;startFill=1;startSize=10;endArrow=oval;endFill=1;endSize=18;')


def png_size(path):
    with open(path, 'rb') as f:
        head = f.read(24)
    return struct.unpack('>II', head[16:24])


def exit_side(circle, target):
    """Side of the circle the line leaves from - the one facing the target."""
    cx, cy = circle[0] + CIRCLE_SIZE / 2, circle[1] + CIRCLE_SIZE / 2
    dx, dy = target[0] - cx, target[1] - cy
    if abs(dx) >= abs(dy):
        return (1, 0.5) if dx > 0 else (0, 0.5)
    return (0.5, 1) if dy > 0 else (0.5, 0)


def main():
    spec_path = sys.argv[1]
    spec = json.load(open(spec_path, encoding='utf8'))
    image = os.path.join(HERE, spec['image'])
    output = os.path.join(REPO, spec['output'])
    callouts = spec.get('callouts', [])
    areas = spec.get('areas', [])
    paths = spec.get('paths', [])

    if not callouts and not areas and not paths:
        if not output.endswith('.png'):
            raise SystemExit('a spec without annotations must point to a .png output')
        shutil.copyfile(image, output)
        print(output)
        return
    if not output.endswith('.drawio'):
        raise SystemExit('an annotated spec must point to a .drawio output')

    width, height = png_size(image)
    data = base64.b64encode(open(image, 'rb').read()).decode('ascii')
    cells = ['<mxCell id="0"/>', '<mxCell id="1" parent="0"/>']
    cells.append(
        '<mxCell id="screenshot" value="" style="shape=image;verticalLabelPosition=bottom;labelBackgroundColor=#ffffff;'
        'verticalAlign=top;aspect=fixed;imageAspect=0;image=data:image/png,%s;connectable=0;allowArrows=0;" '
        'vertex="1" parent="1"><mxGeometry x="0" y="0" width="%d" height="%d" as="geometry"/></mxCell>'
        % (data, width, height))

    for i, area in enumerate(areas):
        x, y, w, h = area['rect']
        cells.append('<mxCell id="area%d" value="" style="%s" vertex="1" parent="1">'
                     '<mxGeometry x="%d" y="%d" width="%d" height="%d" as="geometry"/></mxCell>'
                     % (i, AREA_STYLE, x, y, w, h))

    for i, path in enumerate(paths):
        pts = path['points']
        waypoints = ''.join('<mxPoint x="%d" y="%d"/>' % tuple(p) for p in pts[1:-1])
        cells.append('<mxCell id="pathline%d" value="" style="%s" edge="1" parent="1"><mxGeometry relative="1" as="geometry">'
                     '<mxPoint x="%d" y="%d" as="sourcePoint"/><mxPoint x="%d" y="%d" as="targetPoint"/>'
                     '<Array as="points">%s</Array></mxGeometry></mxCell>'
                     % (i, PATH_STYLE, pts[0][0], pts[0][1], pts[-1][0], pts[-1][1], waypoints))

    for c in callouts:
        n = c['n']
        x, y = c['circle']
        label = '<b><font style="font-size: 39px">%d</font></b>' % n
        cells.append('<mxCell id="callout%d" value=%s style="%s" vertex="1" parent="1">'
                     '<mxGeometry x="%d" y="%d" width="%d" height="%d" as="geometry"/></mxCell>'
                     % (n, quoteattr(label), CIRCLE_STYLE, x, y, CIRCLE_SIZE, CIRCLE_SIZE))
        # "targets" draws several lines from one circle, e.g. to both ends of a range
        targets = c.get('targets', [c['target']] if 'target' in c else [])
        for t, (tx, ty) in enumerate(targets):
            ex, ey = exit_side(c['circle'], (tx, ty))
            style = EDGE_STYLE + 'exitX=%g;exitY=%g;exitDx=0;exitDy=0;' % (ex, ey)
            cells.append('<mxCell id="line%d_%d" value="" style="%s" edge="1" parent="1" source="callout%d">'
                         '<mxGeometry relative="1" as="geometry"><mxPoint x="%d" y="%d" as="targetPoint"/>'
                         '</mxGeometry></mxCell>' % (n, t, style, n, tx, ty))

    # lines are drawn below the circles, so they are listed first
    lines = [c for c in cells if c.startswith('<mxCell id="line')]
    others = [c for c in cells if not c.startswith('<mxCell id="line')]
    ordered = others[:3 + len(areas)] + lines + others[3 + len(areas):]

    xml = ('<mxfile host="annotate.py"><diagram id="screenshot" name="Page-1"><mxGraphModel grid="0" page="0" '
           'math="0" shadow="0"><root>%s</root></mxGraphModel></diagram></mxfile>' % ''.join(ordered))
    with open(output, 'w', encoding='utf8') as f:
        f.write(xml)
    print(output)


if __name__ == '__main__':
    main()
