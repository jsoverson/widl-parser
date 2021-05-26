{
const ast = require('@wapc/widl-ast');
function widlLocation() {
  const loc = location();
  return new ast.Location(loc.start.offset, loc.end.offset, "");
}
function annotations() {
  //placeholder
  return undefined;
}

}

WIDL
  = ws values:definition* ws { return new ast.Document(widlLocation(), values); }

ws "whitespace" = [ \t\n\r]*
hws "horizontal whitespace" = [ \t]*
eol "end of line" = hws [\n\r]+


definition "definition"
  = ws def:(namespaceDefinition / typeDefinition / interfaceDefinition / enumDefinition / importDefinition) ws
  {
    return def;
  }

namespaceDefinition "namespace definition" = namespaceKeyword ws name:string  { return new ast.NamespaceDefinition(widlLocation(), name, undefined, annotations() ); }

importDefinition "import definition" =
  importKeyword ws imports:(@wildcardImport / beginObjectChar ws @importName* ws endObjectChar) ws
  fromKeyword ws from:string
  {
    const all = imports === '*';
    const names = all ? [] : imports;
    return new ast.ImportDefinition(widlLocation(),undefined,all,names,from, annotations());
  }

importName = name:identifier ws alias:(renameKeyword ws @identifier)? argumentSeparator?
  {
    return new ast.ImportName(widlLocation(), name, alias || undefined);
  }


typeDefinition "type definition" =
  typeKeyword ws name:identifier ws beginObjectChar ws fields:(ws @typeField eol)* ws endObjectChar
  {
    return new ast.TypeDefinition(widlLocation(), name, undefined, /*interfaces?*/[], annotations(), fields);
  }

enumDefinition "enum definition" =
  enumKeyword ws name:identifier ws beginObjectChar ws values:(ws @enumValue eol)* ws endObjectChar
  {
    return new ast.EnumDefinition(widlLocation(), name, undefined, annotations(), values);
  }

enumValue "enum value" =
  name:identifier ws assignmentOperator index:(ws @integer)? display:(ws @string)?
  {
    return new ast.EnumValueDefinition(widlLocation(), name, undefined, index, display || undefined, annotations());
  }

interfaceDefinition "interface definition" =
  interfaceKeyword ws beginObjectChar ws operations:(ws @operation eol)* ws endObjectChar
  {
    return new ast.InterfaceDefinition(widlLocation(), operations, annotations());
  }

operation "operation" = name:identifier ws beginArgumentsChar args:argument* endArgumentsChar ws kvSeparator type:widlType  { return new ast.OperationDefinition(widlLocation(),name, undefined, args, type, annotations(), false); }

argument "argument" = pair:nameTypePair argumentSeparator? { return new ast.ParameterDefinition(widlLocation(), pair.name, undefined, pair.type, undefined, annotations()); }

typeField "type field" = pair:nameTypePair {return new ast.FieldDefinition(widlLocation(), pair.name, undefined, pair.type, undefined, annotations());}

widlType "valid widl type" =
  type:(@mapType / @listType / @namedType)optional:optionalOperator? {
    if (!!optional) {
      return new ast.Optional(widlLocation(), type);
    } else {
      return type;
    }
  }

namedType =
   name:( "i8" /
  "u8" /
  "i16" /
  "u16" /
  "i32" /
  "u32" /
  "i64" /
  "u64" /
  "f32" /
  "f64" /
  "bool" /
  "string" /
  "datetime" /
  "bytes" /
  "raw" /
  "value" /
  identifier) {
    if (typeof name === 'string') {
      return new ast.Named(widlLocation(), new ast.Name(widlLocation(), name))
    } else {
      return new ast.Named(widlLocation(), name);
    }
  }

nameTypePair = name:identifier kvSeparator type:widlType {return { name, type };}

mapType "map" = beginObjectChar ws keyType:widlType kvSeparator valueType:widlType ws endObjectChar { return new ast.MapType(widlLocation(), keyType, valueType); }

listType "list" = beginListChar ws type:widlType ws endListChar {return new ast.ListType(widlLocation(), type);}

string "string"
  = quotation_mark chars:char* quotation_mark { return new ast.StringValue(widlLocation(), chars.join("")); }

// Keywords

interfaceKeyword = "interface"
namespaceKeyword = "namespace"
typeKeyword = "type"
enumKeyword = "enum"
importKeyword = "import"
renameKeyword = "as"
fromKeyword = "from"

// Operators

wildcardImport = "*"
beginObjectChar = "{"
endObjectChar = "}"
beginListChar = "["
endListChar = "]"
beginArgumentsChar = "("
endArgumentsChar = ")"
argumentSeparator = ws "," ws
kvSeparator = ws ":" ws
optionalOperator = "?"
assignmentOperator = "="

identifier "identifier"
  = start:identifierStartChar rest:identifierOtherChar {
  return new ast.Name(undefined, start + rest.join(""));
}

identifierStartChar = [a-zA-Z_]
identifierOtherChar = [0-9a-zA-Z_]*

integer "integer" = val:DIGIT+ {
  return new ast.IntValue(widlLocation(), parseInt(val.join(""),10))
}

char
  = unescaped
  / escape
    sequence:(
        '"'
      / "\\"
      / "/"
      / "b" { return "\b"; }
      / "f" { return "\f"; }
      / "n" { return "\n"; }
      / "r" { return "\r"; }
      / "t" { return "\t"; }
      / "u" digits:$(HEXDIG HEXDIG HEXDIG HEXDIG) {
          return String.fromCharCode(parseInt(digits, 16));
        }
    )
    { return sequence; }

escape         = "\\"
quotation_mark = '"'
unescaped      = [\x20-\x21\x23-\x5B\x5D-\u10FFFF]

/* ----- Core ABNF Rules ----- */

/* See RFC 4234, Appendix B (http://tools.ietf.org/html/rfc4627). */
DIGIT  = [0-9]
HEXDIG = [0-9a-f]i
