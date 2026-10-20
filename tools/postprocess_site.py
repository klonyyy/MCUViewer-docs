"""SEO and AI-crawler fixes applied to the MyST HTML build before it's deployed.

mystmd doesn't let us change these through myst.yml, so deploy.yml runs this after
`jupyter-book build --html`:

- adds <link rel="canonical">, og:url, og:type and og:site_name to every page,
- removes the "Site not loading correctly? ... BASE_URL" dialog - it only shows when the
  stylesheet fails to load, but crawlers that don't run JavaScript (GPTBot, ClaudeBot,
  PerplexityBot) read it as the first text of every page,
- writes llms.txt (page index) and llms-full.txt (all pages as one Markdown file) from the
  sources, in the order of the toc in myst.yml.

Usage: python tools/postprocess_site.py [build dir]   (default: _build/html)
"""

import re
import sys
from pathlib import Path

SITE = 'https://docs.mcuviewer.com'
ROOT = Path(__file__).resolve().parent.parent
BUILD = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / '_build' / 'html'

NO_CSS_DIALOG = re.compile(r'<dialog id="myst-no-css".*?</dialog>', re.S)


def page_url(html_file):
    rel = html_file.relative_to(BUILD).parent.as_posix()
    return f'{SITE}/' if rel == '.' else f'{SITE}/{rel}/'


def fix_html(html_file):
    html = html_file.read_text(encoding='utf-8')
    html = NO_CSS_DIALOG.sub('', html)
    if 'rel="canonical"' not in html:
        url = page_url(html_file)
        tags = (
            f'<link rel="canonical" href="{url}"/>'
            f'<meta property="og:url" content="{url}"/>'
            '<meta property="og:type" content="website"/>'
            '<meta property="og:site_name" content="MCUViewer Documentation"/>'
        )
        html = html.replace('</head>', tags + '</head>', 1)
    html_file.write_text(html, encoding='utf-8')


# --- llms.txt / llms-full.txt -------------------------------------------------------

def toc_files():
    myst = (ROOT / 'myst.yml').read_text(encoding='utf-8')
    return re.findall(r'^\s*- file:\s*(\S+\.md)\s*$', myst, re.M)


def project_description():
    myst = (ROOT / 'myst.yml').read_text(encoding='utf-8')
    return re.search(r'^\s*description:\s*"(.*)"\s*$', myst, re.M).group(1)


def split_frontmatter(text):
    m = re.match(r'---\n(.*?)\n---\n', text, re.S)
    if not m:
        return {}, text
    meta = dict(re.findall(r'^(\w+):\s*"?(.*?)"?\s*$', m.group(1), re.M))
    return meta, text[m.end():]


def slug(md_path):
    # mystmd names pages after the file, lowercased, with "_" replaced by "-".
    return md_path.stem.lower().replace('_', '-')


def collect_labels(pages):
    """Maps every (Label)= target to the text of the heading below it."""
    labels = {}
    for _, _, body in pages:
        for label, heading in re.findall(r'^\((\w+)\)=\s*\n+#+\s+(.+?)\s*$', body, re.M):
            labels[label] = heading
    return labels


def to_plain_markdown(body, labels):
    """Turns MyST-specific syntax into plain Markdown an LLM reads without guessing."""
    # Directives may be indented inside list items - group 1 is the indentation.
    def figure(m):
        alt = re.search(r'^\s*:alt:\s*(.+)$', m.group(2), re.M)
        return f'{m.group(1)}[Figure: {alt.group(1)}]' if alt else ''

    def admonition(m):
        indent, kind, content = m.group(1), m.group(2), m.group(3)
        lines = [line[len(indent):] if line.startswith(indent) else line.lstrip() for line in content.strip('\n').split('\n')]
        quoted = '\n'.join(f'{indent}> {line}' if line.strip() else f'{indent}>' for line in lines)
        return f'{indent}> **{kind.capitalize()}:**\n{quoted}'

    body = re.sub(r'^([ \t]*)```\{figure\}[^\n]*\n(.*?)^\1```[ \t]*$', figure, body, flags=re.S | re.M)
    body = re.sub(r'^([ \t]*)```\{(note|warning|tip|important|caution|attention|hint|seealso)\}[^\n]*\n(.*?)^\1```[ \t]*$',
                  admonition, body, flags=re.S | re.M)
    body = re.sub(r'^\(\w+\)=\s*\n', '', body, flags=re.M)
    body = re.sub(r'\{ref\}`([^`<]+?)\s*<(\w+)>`', r'\1', body)
    body = re.sub(r'\{ref\}`(\w+)`', lambda m: labels.get(m.group(1), m.group(1)), body)
    body = re.sub(r'\[([^\]]+)\]\(#\w+\)', r'\1', body)
    return re.sub(r'\n{3,}', '\n\n', body).strip()


def write_llms_files():
    pages = []
    for file in toc_files():
        meta, body = split_frontmatter((ROOT / file).read_text(encoding='utf-8').replace('\r\n', '\n'))
        pages.append((Path(file), meta, body))
    labels = collect_labels(pages)
    home_description = project_description()

    index = [
        '# MCUViewer Documentation',
        '',
        f'> {home_description}',
        '',
        'MCUViewer (formerly STMViewer) is a desktop tool for Windows, Linux and macOS that plots '
        'microcontroller variables in real time, views SWO trace data and records high-speed signals '
        'through the debug probe already connected to the target, without halting the MCU. '
        'Product overview, pricing and downloads: https://mcuviewer.com (see https://mcuviewer.com/llms.txt).',
        '',
        '## Pages',
        '',
    ]
    full = [
        '# MCUViewer Documentation',
        '',
        f'> {home_description}',
        '',
        'MCUViewer was formerly called STMViewer. Website and downloads: https://mcuviewer.com',
    ]
    for path, meta, body in pages:
        url = f'{SITE}/' if path.stem == 'Introduction' else f'{SITE}/{slug(path)}/'
        title = re.search(r'^#\s+(.+?)\s*$', body, re.M).group(1)
        description = meta.get('description', home_description)
        index.append(f'- [{title}]({url}): {description}')
        full += ['', '---', '', f'Source: {url}', '', to_plain_markdown(body, labels)]
    index += [
        '',
        '## Optional',
        '',
        f'- [All pages in one Markdown file]({SITE}/llms-full.txt)',
        '- [MCUViewer website](https://mcuviewer.com/): features, tutorials, pricing and downloads',
    ]
    (BUILD / 'llms.txt').write_text('\n'.join(index) + '\n', encoding='utf-8')
    (BUILD / 'llms-full.txt').write_text('\n'.join(full) + '\n', encoding='utf-8')


if __name__ == '__main__':
    # Pages are index.html at the root and <page>/index.html - nothing deeper.
    html_files = [BUILD / 'index.html', *sorted(BUILD.glob('*/index.html'))]
    for html_file in html_files:
        fix_html(html_file)
    write_llms_files()
    print(f'Post-processed {len(html_files)} pages, wrote llms.txt and llms-full.txt')
