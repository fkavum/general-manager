# -*- coding: utf-8 -*-
"""Regenerate the <Compile Include> list of Unity's generated Assembly-CSharp(.Editor).csproj from the files on disk.
Usage: regen_csproj.py <project-root> [--exclude <AssetsRelPrefix>]... [--suffix NAME] [--check]
  --check: only compare the computed list with the csproj's current list (before any move).
  --suffix twin: write <suffix>.Assembly-CSharp.csproj / <suffix>.Assembly-CSharp-Editor.csproj instead of overwriting."""
import os, re, sys
root=sys.argv[1]; args=sys.argv[2:]
excl=[]; suffix=None; check=False
i=0
while i<len(args):
    if args[i]=='--exclude': excl.append(args[i+1].replace('/',os.sep)); i+=2
    elif args[i]=='--suffix': suffix=args[i+1]; i+=2
    elif args[i]=='--check': check=True; i+=1
    else: raise SystemExit('bad arg '+args[i])
assets=os.path.join(root,'Assets')
# asmdef folders → other assemblies
asm_dirs=[]
for dp,dn,fn in os.walk(assets):
    if any(f.endswith('.asmdef') for f in fn): asm_dirs.append(dp)
def in_asm(p): return any(p==d or p.startswith(d+os.sep) for d in asm_dirs)
FIRSTPASS=('Plugins','Standard Assets','Pro Standard Assets')
main=[]; editor=[]
for dp,dn,fn in os.walk(assets):
    rel=os.path.relpath(dp,assets)
    parts=[] if rel=='.' else rel.split(os.sep)
    dn[:]=[d for d in dn if not d.endswith('~') and not d.startswith('.')]
    if in_asm(dp): continue
    if parts and parts[0] in FIRSTPASS: continue
    relA=os.path.relpath(dp,root)
    if any(relA==e or relA.startswith(e+os.sep) for e in excl): continue
    is_editor='Editor' in parts
    for f in fn:
        if f.endswith('.cs') and not f.startswith('.'):
            (editor if is_editor else main).append(os.path.join(relA,f))
def rewrite(name, files):
    src=os.path.join(root,name+'.csproj'); s=open(src,encoding='utf-8').read()
    cur=re.findall(r'<Compile Include="([^"]+)" />',s)
    curset=set(x.replace('\\','/') for x in cur); new=set(x.replace(os.sep,'/') for x in files)
    if check:
        print(f"{name}: csproj {len(curset)} vs disk {len(new)}; only-in-csproj {sorted(curset-new)[:8]}; only-on-disk {sorted(new-curset)[:8]}")
        return
    items='\n'.join(f'    <Compile Include="{x.replace("/",chr(92))}" />' for x in sorted(new))
    first=s.index('<Compile Include=')
    first=s.rfind('\n',0,first)
    s2=re.sub(r'\n\s*<Compile Include="[^"]+" />','',s)
    s2=s2[:first]+'\n'+items+s2[first:]
    out=os.path.join(root,(suffix+'.' if suffix else '')+name+'.csproj')
    if suffix:
        s2=s2.replace('<ProjectReference Include="Assembly-CSharp.csproj">',f'<ProjectReference Include="{suffix}.Assembly-CSharp.csproj">')
        # same assembly names (the Facebook SDK grants InternalsVisibleTo("Assembly-CSharp")); separate output folders
        s2=re.sub(r'<OutputPath>([^<]*)</OutputPath>', lambda m: f'<OutputPath>{m.group(1).rstrip(chr(92))}{chr(92)}{suffix}{chr(92)}</OutputPath>', s2)
        s2=re.sub(r'<BaseIntermediateOutputPath>([^<]*)</BaseIntermediateOutputPath>', lambda m: f'<BaseIntermediateOutputPath>{m.group(1).rstrip(chr(92))}{chr(92)}{suffix}{chr(92)}</BaseIntermediateOutputPath>', s2)
    open(out,'w',encoding='utf-8').write(s2); print(f"wrote {out} ({len(new)} files)")
rewrite('Assembly-CSharp',main); rewrite('Assembly-CSharp-Editor',editor)
