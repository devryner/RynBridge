export interface SchemaProperty {
  type: string;
  description?: string;
  enum?: string[];
  items?: { type: string };
  format?: string;
  minimum?: number;
  maximum?: number;
}

export interface Schema {
  $schema?: string;
  $id?: string;
  title: string;
  description?: string;
  type: string;
  properties: Record<string, SchemaProperty>;
  required?: string[];
  additionalProperties?: boolean;
}

export interface ActionSchema {
  action: string;
  request: Schema;
  response?: Schema;
}

export interface ModuleSchemaMap {
  [moduleName: string]: ActionSchema[];
}

export interface GeneratorOptions {
  moduleName: string;
  actions: ActionSchema[];
}
