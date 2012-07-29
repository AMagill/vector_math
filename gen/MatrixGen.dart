/*

  VectorMath.dart
  
  Copyright (C) 2012 John McCutchan <john@johnmccutchan.com>
  
  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/

#import ('dart:builtin');
#import ('dart:io');

class MatrixGen {
  int rows;
  int cols;
  String get rowVecType() => 'vec$cols';
  String get colVecType() => 'vec$rows';
  String get matType() => 'mat${cols}x${rows}';
  String floatArrayType;
  
  int _indent;
  RandomAccessFile out;
  MatrixGen() {
    floatArrayType = 'Woops';
    _indent = 0;
  }
  
  List<String> get matrixComponents() {
    List<String> r = new List<String>();
    for (int i = 0; i < cols; i++) {
      r.add('col$i');  
    }
    return r;
  }
  String matTypeTransposed() {
    return 'mat${rows}x${cols}';
  }
  
  void iPush() {
    _indent++;
  }
  void iPop() {
    _indent--;
    assert(_indent >= 0);
  }
  void iPrint(String s) {
    String indent = "";
    for (int i = 0; i < _indent; i++) {
      indent = '$indent  ';
    }
    out.writeStringSync('$indent$s\n');
    print('$indent$s');
  }
  
  void writeLicense() {
    iPrint('''/*

  VectorMath.dart
  
  Copyright (C) 2012 John McCutchan <john@johnmccutchan.com>
  
  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

*/''');
  }
  
  String Access(int row, int col, [String pre = 'col']) {
    //assert(row < rows && row >= 0);
    //assert(col < cols && col >= 0);
    String rowName = '';
    if (row == 0) {
      rowName = 'x';
    } else if (row == 1) {
      rowName = 'y';
    } else if (row == 2) {
      rowName = 'z';
    } else if (row == 3) {
      rowName = 'w';
    } else {
      assert(row < 4);
    }
    return '$pre$col.$rowName';
  }
  
  String AccessV(int row) {
    String rowName = '';
    if (row == 0) {
      rowName = 'x';
    } else if (row == 1) {
      rowName = 'y';
    } else if (row == 2) {
      rowName = 'z';
    } else if (row == 3) {
      rowName = 'w';
    } else {
      assert(row < 4 && row >= 0);
    }
    return rowName;
  }
  
  void generatePrologue() {
    iPrint('\/\/\/ ${matType} is a column major matrix where each column is represented by [$colVecType]. This matrix has $cols columns and $rows rows.');
    iPrint('class ${matType} {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('$colVecType col$i;');  
    }
  }
  
  String joinStrings(List<String> elements, [String pre = '', String post = '', String joiner = ', ']) {
    bool first = true;
    String r = '';
    for (String e in elements) {
      var extra = first ? '${pre}${e}${post}' : '${joiner}${pre}${e}${post}'; 
      r = '$r$extra'; 
      first = false;
    }
    return r;
  }
  
  void generateConstructors() {
    int numArguments = cols * rows;
    List<String> arguments = new List<String>(numArguments);
    for (int i = 0; i < numArguments; i++) {
      arguments[i] = 'arg$i';
    }
    List<String> columnArguments = new List<String>(cols);
    for (int i = 0; i < cols; i++) {
      columnArguments[i] = 'arg$i';
    }
    iPrint('\/\/\/ Constructs a new ${matType}. Supports GLSL like syntax so many possible inputs. Defaults to identity matrix.');
    iPrint('${matType}([${joinStrings(arguments, 'Dynamic ')}]) {');
    iPush();
    iPrint('//Initialize the matrix as the identity matrix');
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = new $colVecType.zero();');
    }
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        if (i == j) {
          iPrint('${Access(j, i)} = 1.0;');  
        }
      }
    }
    
    iPrint('if (${joinStrings(arguments, '', ' is num', ' && ')}) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j, i)} = arg${(i*rows)+j};');
      }
    }
    iPrint('return;');
    iPop();
    iPrint('}');
    
    iPrint('if (arg0 is num && ${joinStrings(arguments.getRange(1, numArguments-1), '', ' == null', ' && ')}) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        if (i == j) {
          iPrint('${Access(j, i)} = arg0;');  
        }
      }
    }
    iPrint('return;');
    iPop();
    iPrint('}');
    
    iPrint('if (${joinStrings(columnArguments, '', ' is vec${cols}', ' && ')}) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = arg$i;');
    }
    iPrint('return;');
    iPop();
    iPrint('}');
    
    iPrint('if (arg0 is ${matType}) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = arg0.col$i;');
    }
    iPrint('return;');
    iPop();
    iPrint('}');
    
    for (int i = cols; i >= 2; i--) {
      for (int j = rows; j >= 2; j--) {
        if (i == cols && j == rows) {
          continue;
        }
        iPrint('if (arg0 is mat${i}x${j}) {');
        iPush();
        for (int k = 0; k < i; k++) {
          for (int l = 0; l < j; l++) {
            iPrint('${Access(l, k)} = arg0.${Access(l, k)};');
          }
        }
        iPrint('return;');
        iPop();
        iPrint('}');
      }
    }
    
    int diagonals = rows < cols ? rows : cols;
    for (int i = 1; i < diagonals; i++) {
      iPrint('if (arg0 is vec${i+1} && ${joinStrings(arguments.getRange(1, numArguments-1), '', ' == null', ' && ')}) {');
      iPush();
      for (int j = 0; j < i+1; j++) {
        iPrint('${Access(j, j)} = arg0.${AccessV(j)};');
      }
      iPop();
      iPrint('}');
    }
    
    iPop();
    iPrint('}');
    
    // Outer product constructor
    iPrint('\/\/\/ Constructs a new [${matType}] from computing the outer product of [u] and [v].');
    iPrint('${matType}.outer(vec${cols} u, vec${rows} v) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = new $colVecType();');
    }
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j, i)} = u.${AccessV(i)} * v.${AccessV(j)};');
      }
    }
    iPop();
    iPrint('}');
    
    iPrint('\/\/\/ Constructs a new [${matType}] filled with zeros.');
    iPrint('${matType}.zero() {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = new $colVecType();');
    }
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j, i)} = 0.0;');
      }
    }
    iPop();
    iPrint('}');
    
    iPrint('\/\/\/ Constructs a new identity [${matType}].');
    iPrint('${matType}.identity() {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = new $colVecType();');
    }
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        if (i == j) {
          iPrint('${Access(j, i)} = 1.0;');
        } else {
          iPrint('${Access(j, i)} = 0.0;');  
        }
      }
    }
    iPop();
    iPrint('}');
    
    iPrint('\/\/\/ Constructs a new [${matType}] which is a copy of [other].');
    iPrint('${matType}.copy($matType other) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = new $colVecType();');
    }
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j, i)} = other.${Access(j, i)};');
      }
    }
    iPop();
    iPrint('}');
    
    if (rows == 2 && cols == 2) {
      iPrint('\/\/\/ Constructs a new [${matType}] representing a rotation by [radians].');
      iPrint('${matType}.rotation(num radians_) {');
      iPush();
      for (int i = 0; i < cols; i++) {
        iPrint('col$i = new $colVecType.zero();');
      }
      iPrint('setRotation(radians_);');
      iPop();
      iPrint('}');  
    }
    
    if ((rows == 3 && cols == 3) || (rows == 4 && cols == 4)) {
      iPrint('\/\/\/\/ Constructs a new [${matType}] representation a rotation of [radians] around the X axis');
      iPrint('${matType}.rotationX(num radians_) {');
      iPush();
      for (int i = 0; i < cols; i++) {
        iPrint('col$i = new $colVecType.zero();');
      }
      if (rows == 4 && cols == 4) {
        iPrint('col3.w = 1.0;');
      }
      iPrint('setRotationAroundX(radians_);');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/\/ Constructs a new [${matType}] representation a rotation of [radians] around the Y axis');
      iPrint('${matType}.rotationY(num radians_) {');
      iPush();
      for (int i = 0; i < cols; i++) {
        iPrint('col$i = new $colVecType.zero();');
      }
      if (rows == 4 && cols == 4) {
        iPrint('col3.w = 1.0;');
      }
      iPrint('setRotationAroundY(radians_);');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/\/ Constructs a new [${matType}] representation a rotation of [radians] around the Z axis');
      iPrint('${matType}.rotationZ(num radians_) {');
      iPush();
      for (int i = 0; i < cols; i++) {
        iPrint('col$i = new $colVecType.zero();');
      }
      if (rows == 4 && cols == 4) {
        iPrint('col3.w = 1.0;');
      }
      iPrint('setRotationAroundZ(radians_);');
      iPop();
      iPrint('}');
    }
    
    if (rows == 4 && cols == 4) {
      iPrint('\/\/\/\/ Constructs a new [${matType}] representening a [translation]');
      iPrint('${matType}.translate(vec3 translation) {');
      iPush();
      for (int i = 0; i < cols; i++) {
        iPrint('col$i = new $colVecType.zero();');
      }
      iPrint('col0.x = 1.0;');
      iPrint('col1.y = 1.0;');
      iPrint('col2.z = 1.0;');
      iPrint('col3.w = 1.0;');
      iPrint('col3.xyz = translation;');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/\/ Constructs a new [${matType}] representening a translation of [x], [y], and [z]');
      iPrint('${matType}.translateRaw(num x, num y, num z) {');
      iPush();
      for (int i = 0; i < cols; i++) {
        iPrint('col$i = new $colVecType.zero();');
      }
      iPrint('col0.x = 1.0;');
      iPrint('col1.y = 1.0;');
      iPrint('col2.z = 1.0;');
      iPrint('col3.w = 1.0;');
      iPrint('col3.x = x;');
      iPrint('col3.y = y;');
      iPrint('col3.z = z;');
      iPop();
      iPrint('}');
    }
    
    iPrint('${matType}.raw(${joinStrings(arguments, 'num ')}) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('col$i = new $colVecType.zero();');
    }
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j, i)} = arg${(i*rows)+j};');
      }
    }
    iPop();
    iPrint('}');
  }
  
  void generateRowColProperties() {
    iPrint('\/\/\/ Returns the number of rows in the matrix.');
    iPrint('num get rows() => $rows;');
    iPrint('\/\/\/ Returns the number of columns in the matrix.');
    iPrint('num get cols() => $cols;');
    iPrint('\/\/\/ Returns the number of columns in the matrix.');
    iPrint('num get length() => $cols;');
  }
  
  void generateRowGetterSetters() {
    for (int i = 0; i < rows; i++) {
      iPrint('\/\/\/ Returns row $i');
      iPrint('$rowVecType get row$i() => getRow($i);');
    }
    for (int i = 0; i < rows; i++) {
      iPrint('\/\/\/ Sets row $i to [arg]');
      iPrint('set row$i($rowVecType arg) => setRow($i, arg);');
    }
  }
  
  void generateIndexOperator() {
    iPrint('\/\/\/ Gets the [column] of the matrix');
    iPrint('$colVecType operator[](int column) {');
    iPush();
    iPrint('assert(column >= 0 && column < $cols);');
    iPrint('switch (column) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('case $i: return col$i;');
    }
    iPop();
    iPrint('}');
    iPrint('throw new IllegalArgumentException(column);');
    iPop();
    iPrint('}');
  }
  
  void generateAssignIndexOperator() {
    iPrint('\/\/\/ Assigns the [column] of the matrix [arg]');
    iPrint('void operator[]=(int column, $colVecType arg) {');
    iPush();
    iPrint('assert(column >= 0 && column < $cols);');
    iPrint('switch (column) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      iPrint('case $i: col$i = arg; break;');
    }
    iPop();
    iPrint('}');
    iPrint('throw new IllegalArgumentException(column);');
    iPop();
    iPrint('}');
  }
  
  void generateRowHelpers() {
    iPrint('\/\/\/ Assigns the [column] of the matrix [arg]');
    iPrint('void setRow(int row, $rowVecType arg) {');
    iPush();
    iPrint('assert(row >= 0 && row < $rows);');
    for (int i = 0; i < cols; i++) {
      iPrint('col$i[row] = arg.${AccessV(i)};');
    }
    iPop();
    iPrint('}');
    
    iPrint('\/\/\/ Gets the [row] of the matrix');
    iPrint('$rowVecType getRow(int row) {');
    iPush();
    iPrint('assert(row >= 0 && row < $rows);');
    iPrint('${rowVecType} r = new ${rowVecType}();');
    for (int i = 0; i < cols; i++) {
      iPrint('r.${AccessV(i)} = col$i[row];');
    }
    iPrint('return r;');
    iPop();
    iPrint('}');
  }
  
  void generateColumnHelpers() {
    iPrint('\/\/\/ Assigns the [column] of the matrix [arg]');
    iPrint('void setColumn(int column, $colVecType arg) {');
    iPush();
    iPrint('assert(column >= 0 && column < $cols);');
    iPrint('this[column] = arg;');
    iPop();
    iPrint('}');
    
    iPrint('\/\/\/ Gets the [column] of the matrix');
    iPrint('$colVecType getColumn(int column) {');
    iPush();
    iPrint('assert(column >= 0 && column < $cols);');
    iPrint('return new ${colVecType}(this[column]);');
    iPop();
    iPrint('}');
  }
  
  void generateToString() {
    iPrint('\/\/\/ Returns a printable string');
    iPrint('String toString() {');
    iPush();
    iPrint('String s = \'\';');
    for (int i = 0; i < rows; i++) {
      iPrint('s = \'\$s[$i] \${getRow($i)}\\n\';');
    }
    iPrint('return s;');
    iPop();
    iPrint('}');
  }
  
  void generateEpilogue() {
    iPop();
    iPrint('}');
  }
  
  String generateInlineDot(String rowPrefix, int row, String col, int len) {
    String r = '';
    for (int i = 0; i < len; i++) {
      if (i != 0) {
        r = '$r +'; 
      }
      r = '$r (${rowPrefix}.${Access(row, i)} * ${col}.${AccessV(i)})';
    }
    return r;
  }
  
  void generateMatrixVectorMultiply() {
    iPrint('$colVecType r = new $colVecType.zero();');
    for (int i = 0; i < rows; i++) {
      iPrint('r.${AccessV(i)} = ${generateInlineDot('this', i, 'arg', cols)};');
    }
    iPrint('return r;');
  }
  
  void generateMatrixVectorMultiply3() {
    iPrint('vec3 r = new vec3.zero();');
    for (int i = 0; i < 3; i++) {
      iPrint('r.${AccessV(i)} = ${generateInlineDot('this', i, 'arg', 3)};');
    }
    iPrint('return r;');
  }
  
  
  String generateInlineDotM(String rowPrefix, String colPrefix, int srow, int scol, int len) {
    String r = '';
    for (int i = 0; i < len; i++) {
      if (i != 0) {
        r = '$r +'; 
      }
      r = '$r (${rowPrefix}.${Access(srow, i)} * ${colPrefix}.${Access(i, scol)})';
    }
    return r;
  }
  
  void generateMatrixMatrixMultiply() {
    iPrint('Dynamic r = null;');
    
    iPrint('if (arg.cols == 2) {');
    iPush();
    iPrint('r = new mat2x${rows}.zero();');
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < 2; j++) {
        iPrint('r.${Access(i, j)} = ${generateInlineDotM('this', 'arg', i, j, cols)};');
      }
    }
    iPrint('return r;');
    iPop();
    iPrint('}');
    
    if (rows >= 3) {
      iPrint('if (arg.cols == 3) {');
      iPush();
      iPrint('r = new mat3x${rows}.zero();');
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < 3; j++) {
          iPrint('r.${Access(i, j)} = ${generateInlineDotM('this', 'arg', i, j, cols)};');
        }
      }

      iPrint('return r;');
      iPop();
      iPrint('}');
    }
    
    if (rows >= 4) {
      iPrint('if (arg.cols == 4) {');
      iPush();
      iPrint('r = new mat4x${rows}.zero();');
      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < 4; j++) {
          iPrint('r.${Access(i, j)} = ${generateInlineDotM('this', 'arg', i, j, cols)};');
        }
      }
      iPrint('return r;');
      iPop();
      iPrint('}');  
    }
    
    iPrint('return r;');
  }
  
  void generateMatrixScale() {
    iPrint('${matType} r = new ${matType}.zero();');
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('r.${Access(j, i)} = ${Access(j, i)} * arg;');
      }
    }
    iPrint('return r;');
  }
  
  void generateMult() {
    iPrint('\/\/\/ Returns a new vector or matrix by multiplying [this] with [arg].');
    iPrint('Dynamic operator*(Dynamic arg) {');
    iPush();
    iPrint('if (arg is num) {');
    iPush();
    generateMatrixScale();
    iPop();
    iPrint('}');
    iPrint('if (arg is $rowVecType) {');
    iPush();
    generateMatrixVectorMultiply();
    iPop();
    iPrint('}');
    if (matType == 'mat4x4') {
      iPrint('if (arg is vec3) {');
      iPush();
      generateMatrixVectorMultiply3();
      iPop();
      iPrint('}');
    }
    iPrint('if ($cols == arg.rows) {');
    iPush();
    generateMatrixMatrixMultiply();
    iPop();
    iPrint('}');
    iPrint('throw new IllegalArgumentException(arg);');
    iPop();
    iPrint('}');
  }
  
  void generateOp(String op) {
    iPrint('\/\/\/ Returns new matrix after component wise [this] $op [arg]');
    iPrint('${matType} operator$op(${matType} arg) {');
    iPush();
    iPrint('${matType} r = new ${matType}();');
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('r.${Access(j, i)} = ${Access(j, i)} $op arg.${Access(j, i)};');
      }
    }
    iPrint('return r;');
    iPop();
    iPrint('}');
  }
  
  void generateNegate() {
    iPrint('\/\/\/ Returns new matrix -this');
    iPrint('${matType} operator negate() {');
    iPush();
    iPrint('${matType} r = new ${matType}();');
    for (int i = 0; i < cols; i++) {
      iPrint('r[$i] = -this[$i];');  
    }
    iPrint('return r;');
    iPop();
    iPrint('}');
  }
  
  void generateTranspose() {
    iPrint('\/\/\/ Returns the tranpose of this.');
    iPrint('${matTypeTransposed()} transposed() {');
    iPush();
    iPrint('${matTypeTransposed()} r = new ${matTypeTransposed()}();');
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        iPrint('r.${Access(j, i)} = ${Access(i, j)};');
      }
    }
    iPrint('return r;');
    iPop();
    iPrint('}');
  }
  
  void generateAbsolute() {
    iPrint('\/\/\/ Returns the component wise absolute value of this.');
    iPrint('${matType} absolute() {');
    iPush();
    iPrint('${matType} r = new ${matType}();');
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('r.${Access(j, i)} = ${Access(j, i)}.abs();');
      }
    }
    iPrint('return r;');
    iPop();
    iPrint('}');
  }
  
  void generateDeterminant() {
    if (matType == 'mat2x2') {
      iPrint('\/\/\/ Returns the determinant of this matrix.');
      iPrint('num determinant() {');
      iPush();
      iPrint('return (col0.x * col1.y) - (col0.y*col1.x);');
      iPop();
      iPrint('}');
    }
    
    if (matType == 'mat3x3') {
      iPrint('\/\/\/ Returns the determinant of this matrix.');
      iPrint('num determinant() {');
      iPush();
      iPrint('num x = col0.x*((col1.y*col2.z)-(col1.z*col2.y));');
      iPrint('num y = col0.y*((col1.x*col2.z)-(col1.z*col2.x));');
      iPrint('num z = col0.z*((col1.x*col2.y)-(col1.y*col2.x));');
      iPrint('return x - y + z;');
      iPop();
      iPrint('}');
    }
    
    if (matType == 'mat4x4') {
      iPrint('\/\/\/ Returns the determinant of this matrix.');
      iPrint('num determinant() {');
      iPush();
      iPrint('num det2_01_01 = col0.x * col1.y - col0.y * col1.x;');
      iPrint('num det2_01_02 = col0.x * col1.z - col0.z * col1.x;');
      iPrint('num det2_01_03 = col0.x * col1.w - col0.w * col1.x;');
      iPrint('num det2_01_12 = col0.y * col1.z - col0.z * col1.y;');
      iPrint('num det2_01_13 = col0.y * col1.w - col0.w * col1.y;');
      iPrint('num det2_01_23 = col0.z * col1.w - col0.w * col1.z;');
      iPrint('num det3_201_012 = col2.x * det2_01_12 - col2.y * det2_01_02 + col2.z * det2_01_01;');
      iPrint('num det3_201_013 = col2.x * det2_01_13 - col2.y * det2_01_03 + col2.w * det2_01_01;');
      iPrint('num det3_201_023 = col2.x * det2_01_23 - col2.z * det2_01_03 + col2.w * det2_01_02;');
      iPrint('num det3_201_123 = col2.y * det2_01_23 - col2.z * det2_01_13 + col2.w * det2_01_12;');
      iPrint('return ( - det3_201_123 * col3.x + det3_201_023 * col3.y - det3_201_013 * col3.z + det3_201_012 * col3.w);');
      iPop();
      iPrint('}');
    }
  }
  
  void generateTrace() {
    if (rows == cols) {
      iPrint('\/\/\/ Returns the trace of the matrix. The trace of a matrix is the sum of the diagonal entries');
      iPrint('num trace() {');
      iPush();
      iPrint('num t = 0.0;');
      for (int i = 0; i < cols; i++) {
        iPrint('t += ${Access(i, i)};');
      }
      iPrint('return t;');
      iPop();
      iPrint('}');
    }
  }
  
  void generateInfinityNorm() {
    iPrint('\/\/\/ Returns infinity norm of the matrix. Used for numerical analysis.');
    iPrint('num infinityNorm() {');
    iPush();
    iPrint('num norm = 0.0;');
    for (int i = 0; i < cols; i++) {
      iPrint('{');
      iPush();
      iPrint('num row_norm = 0.0;');
      for (int j = 0; j < rows; j++) {
        iPrint('row_norm += this[$i][$j].abs();');
      }
      iPrint('norm = row_norm > norm ? row_norm : norm;');
      iPop();
      iPrint('}');
    }
    iPrint('return norm;');
    iPop();
    iPrint('}');
  }
  
  void generateError() {
    iPrint('\/\/\/ Returns relative error between [this] and [correct]');
    iPrint('num relativeError($matType correct) {');
    iPush();
    iPrint('num this_norm = infinityNorm();');
    iPrint('num correct_norm = correct.infinityNorm();');
    iPrint('num diff_norm = (this_norm - correct_norm).abs();');
    iPrint('return diff_norm/correct_norm;');
    iPop();
    iPrint('}');
    iPrint('\/\/\/ Returns absolute error between [this] and [correct]');
    iPrint('num absoluteError($matType correct) {');
    iPush();
    iPrint('num this_norm = infinityNorm();');
    iPrint('num correct_norm = correct.infinityNorm();');
    iPrint('num diff_norm = (this_norm - correct_norm).abs();');
    iPrint('return diff_norm;');
    iPop();
    iPrint('}');
  } 
  
  void generateTranslate() {
    if (rows == 4 && cols == 4) {
      iPrint('\/\/\/ Returns the translation vector from this homogeneous transformation matrix.');
      iPrint('vec3 getTranslation() {');
      iPush();
      iPrint('return new vec3(col3.x, col3.y, col3.z);');
      iPop();
      iPrint('}');
      iPrint('\/\/\/ Sets the translation vector in this homogeneous transformation matrix.');
      iPrint('void setTranslation(vec3 T) {');
      iPush();
      iPrint('col3.xyz = T;');
      iPop();
      iPrint('}');
    }
  }
  
  void generateRotation() {
    if (rows == 4 && cols == 4) {
      iPrint('\/\/\/ Returns the rotation matrix from this homogeneous transformation matrix.');
      iPrint('mat3x3 getRotation() {');
      iPush();
      iPrint('mat3x3 r = new mat3x3();');
      iPrint('r.col0 = new vec3(this.col0.x,this.col0.y,this.col0.z);');
      iPrint('r.col1 = new vec3(this.col1.x,this.col1.y,this.col1.z);');
      iPrint('r.col2 = new vec3(this.col2.x,this.col2.y,this.col2.z);');
      iPrint('return r;');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/ Sets the rotation matrix in this homogeneous transformation matrix.');
      iPrint('void setRotation(mat3x3 rotation) {');
      iPush();
      iPrint('this.col0.xyz = rotation.col0;');
      iPrint('this.col1.xyz = rotation.col1;');
      iPrint('this.col2.xyz = rotation.col2;');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/ Transposes just the upper 3x3 rotation matrix.');
      iPrint('void transposeRotation() {');
      iPush();
      iPrint('num temp;');
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (i == j) {
            continue;
          }
          iPrint('temp = this.${Access(j, i)};');
          iPrint('this.${Access(j, i)} = this.${Access(i, j)};');
          iPrint('this.${Access(i, j)} = temp;');
        }
      }
      iPop();
      iPrint('}');
    }
  }
  
  void generateInvert() {
    if (rows != cols) {
      // Only square matrices have inverses
      return;
    }
    
    if (rows == 2) {
      iPrint('\/\/\/ Invert the matrix. Returns the determinant.');
      iPrint('num invert() {');
      iPush();
      iPrint('num det = determinant();');
      iPrint('if (det == 0.0) {');
      iPush();
      iPrint('return 0.0;');
      iPop();
      iPrint('}');
      iPrint('num invDet = 1.0 / det;');
      iPrint('num temp = col0.x;');
      iPrint('col0.x = col1.y * invDet;');
      iPrint('col0.y = - col0.y * invDet;');
      iPrint('col1.x = - col1.x * invDet;');
      iPrint('col1.y = temp * invDet;');
      iPrint('return det;');
      iPop();
      iPrint('}');
    } else if (rows == 3) {
      iPrint('/\/\/\ Invert the matrix. Returns the determinant.');
      iPrint('num invert() {');
      iPush();
      iPrint('num det = determinant();');
      iPrint('if (det == 0.0) {');
      iPush();
      iPrint('return 0.0;');
      iPop();
      iPrint('}');
      iPrint('num invDet = 1.0 / det;');
      iPrint('vec3 i = new vec3.zero();');
      iPrint('vec3 j = new vec3.zero();');
      iPrint('vec3 k = new vec3.zero();');
      iPrint('i.x = invDet * (col1.y * col2.z - col1.z * col2.y);');
      iPrint('i.y = invDet * (col0.z * col2.y - col0.y * col2.z);');
      iPrint('i.z = invDet * (col0.y * col1.z - col0.z * col1.y);');
      iPrint('j.x = invDet * (col1.z * col2.x - col1.x * col2.z);');
      iPrint('j.y = invDet * (col0.x * col2.z - col0.z * col2.x);');
      iPrint('j.z = invDet * (col0.z * col1.x - col0.x * col1.z);');
      iPrint('k.x = invDet * (col1.x * col2.y - col1.y * col2.x);');
      iPrint('k.y = invDet * (col0.y * col2.x - col0.x * col2.y);');
      iPrint('k.z = invDet * (col0.x * col1.y - col0.y * col1.x);');
      iPrint('col0 = i;');
      iPrint('col1 = j;');
      iPrint('col2 = k;');
      iPrint('return det;');
      iPop();
      iPrint('}');
    } else if (rows == 4) {
      iPrint('num invert() {');
      iPush();
      iPrint('num det = determinant();');
      iPrint('if (det == 0.0) {');
      iPush();
      iPrint('return 0.0;');
      iPop();
      iPrint('}');
      iPrint('num invDet = 1.0 / det;');
      iPrint('selfScaleAdjoint(invDet);');
      iPrint('return det;');
      iPop();
      iPrint('}');
      
      iPrint('num invertRotation() {');
      iPush();
      iPrint('num det = determinant();');
      iPrint('if (det == 0.0) {');
      iPush();
      iPrint('return 0.0;');
      iPop();
      iPrint('}');
      iPrint('num invDet = 1.0 / det;');
      iPrint('vec4 i = new vec4.zero();');
      iPrint('vec4 j = new vec4.zero();');
      iPrint('vec4 k = new vec4.zero();');
      iPrint('i.x = invDet * (col1.y * col2.z - col1.z * col2.y);');
      iPrint('i.y = invDet * (col0.z * col2.y - col0.y * col2.z);');
      iPrint('i.z = invDet * (col0.y * col1.z - col0.z * col1.y);');
      iPrint('j.x = invDet * (col1.z * col2.x - col1.x * col2.z);');
      iPrint('j.y = invDet * (col0.x * col2.z - col0.z * col2.x);');
      iPrint('j.z = invDet * (col0.z * col1.x - col0.x * col1.z);');
      iPrint('k.x = invDet * (col1.x * col2.y - col1.y * col2.x);');
      iPrint('k.y = invDet * (col0.y * col2.x - col0.x * col2.y);');
      iPrint('k.z = invDet * (col0.x * col1.y - col0.y * col1.x);');
      iPrint('col0 = i;');
      iPrint('col1 = j;');
      iPrint('col2 = k;');
      iPrint('return det;');
      iPop();
      iPrint('}');
    }
  }
  
  void generateSetRotation() {
    if (rows == 2 && cols == 2) {
      iPrint('\/\/\/ Turns the matrix into a rotation of [radians]');
      iPrint('void setRotation(num radians_) {');
      iPush();
      iPrint('num c = Math.cos(radians_);');
      iPrint('num s = Math.sin(radians_);');
      iPrint('col0.x = c;');
      iPrint('col0.y = s;');
      iPrint('col1.x = -s;');
      iPrint('col1.y = c;');
      iPop();
      iPrint('}');
    }
    if (rows == 3 && cols == 3) {
      iPrint('\/\/\/ Turns the matrix into a rotation of [radians] around X');
      iPrint('void setRotationAroundX(num radians_) {');
      iPush();
      iPrint('num c = Math.cos(radians_);');
      iPrint('num s = Math.sin(radians_);');
      iPrint('col0.x = 1.0;');
      iPrint('col0.y = 0.0;');
      iPrint('col0.z = 0.0;');
      iPrint('col1.x = 0.0;');
      iPrint('col1.y = c;');
      iPrint('col1.z = s;');
      iPrint('col2.x = 0.0;');
      iPrint('col2.y = -s;');
      iPrint('col2.z = c;');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/ Turns the matrix into a rotation of [radians] around Y');
      iPrint('void setRotationAroundY(num radians_) {');
      iPush();
      iPrint('num c = Math.cos(radians_);');
      iPrint('num s = Math.sin(radians_);');
      iPrint('col0.x = c;');
      iPrint('col0.y = 0.0;');
      iPrint('col0.z = -s;');
      iPrint('col1.x = 0.0;');
      iPrint('col1.y = 1.0;');
      iPrint('col1.z = 0.0;');
      iPrint('col2.x = s;');
      iPrint('col2.y = 0.0;');
      iPrint('col2.z = c;');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/ Turns the matrix into a rotation of [radians] around Z');
      iPrint('void setRotationAroundZ(num radians_) {');
      iPush();
      iPrint('num c = Math.cos(radians_);');
      iPrint('num s = Math.sin(radians_);');
      iPrint('col0.x = c;');
      iPrint('col0.y = s;');
      iPrint('col0.z = 0.0;');
      iPrint('col1.x = -s;');
      iPrint('col1.y = c;');
      iPrint('col1.z = 0.0;');
      iPrint('col2.x = 0.0;');
      iPrint('col2.y = 0.0;');
      iPrint('col2.z = 1.0;');
      iPop();
      iPrint('}');
    }
    
    if (rows == 4 && cols == 4) {
      iPrint('\/\/\/ Sets the upper 3x3 to a rotation of [radians] around X');
      iPrint('void setRotationAroundX(num radians_) {');
      iPush();
      iPrint('num c = Math.cos(radians_);');
      iPrint('num s = Math.sin(radians_);');
      iPrint('col0.x = 1.0;');
      iPrint('col0.y = 0.0;');
      iPrint('col0.z = 0.0;');
      iPrint('col1.x = 0.0;');
      iPrint('col1.y = c;');
      iPrint('col1.z = s;');
      iPrint('col2.x = 0.0;');
      iPrint('col2.y = -s;');
      iPrint('col2.z = c;');
      iPrint('col0.w = 0.0;');
      iPrint('col1.w = 0.0;');
      iPrint('col2.w = 0.0;');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/ Sets the upper 3x3 to a rotation of [radians] around Y');
      iPrint('void setRotationAroundY(num radians_) {');
      iPush();
      iPrint('num c = Math.cos(radians_);');
      iPrint('num s = Math.sin(radians_);');
      iPrint('col0.x = c;');
      iPrint('col0.y = 0.0;');
      iPrint('col0.z = -s;');
      iPrint('col1.x = 0.0;');
      iPrint('col1.y = 1.0;');
      iPrint('col1.z = 0.0;');
      iPrint('col2.x = s;');
      iPrint('col2.y = 0.0;');
      iPrint('col2.z = c;');
      iPrint('col0.w = 0.0;');
      iPrint('col1.w = 0.0;');
      iPrint('col2.w = 0.0;');
      iPop();
      iPrint('}');
      
      iPrint('\/\/\/ Sets the upper 3x3 to a rotation of [radians] around Z');
      iPrint('void setRotationAroundZ(num radians_) {');
      iPush();
      iPrint('num c = Math.cos(radians_);');
      iPrint('num s = Math.sin(radians_);');
      iPrint('col0.x = c;');
      iPrint('col0.y = s;');
      iPrint('col0.z = 0.0;');
      iPrint('col1.x = -s;');
      iPrint('col1.y = c;');
      iPrint('col1.z = 0.0;');
      iPrint('col2.x = 0.0;');
      iPrint('col2.y = 0.0;');
      iPrint('col2.z = 1.0;');
      iPrint('col0.w = 0.0;');
      iPrint('col1.w = 0.0;');
      iPrint('col2.w = 0.0;');
      iPop();
      iPrint('}');
    }
  }
  
  String generateInlineDet2(String a, String b, String c, String d) {
    return '($a * $d - $b * $c)';
  }
  
  String generateInlineDet3(String a1, String a2, String a3, String b1, String b2, String b3, String c1, String c2, String c3) {
    return '($a1 * ${generateInlineDet2(b2, b3, c2, c3)} - $b1 * ${generateInlineDet2(a2, a3, c2, c3)} + $c1 * ${generateInlineDet2(a2, a3, b2, b3)})';
  }
  
  void generateAdjugate() {
    if (rows != cols) {
      return;
    }
    
    iPrint('\/\/\/ Converts into Adjugate matrix and scales by [scale]');
    if (rows == 2) {
      iPrint('void selfScaleAdjoint(num scale) {');
      iPush();
      iPrint('num temp = ${Access(0, 0)};');
      iPrint('${Access(0, 0)} = ${Access(1,1)} * scale;');
      iPrint('${Access(0, 1)} = - ${Access(0,1)} * scale;');
      iPrint('${Access(1, 0)} = - ${Access(1, 0)} * scale;');
      iPrint('${Access(1, 1)} = temp * scale;');
      iPop();
      iPrint('}');
    }
    
    if (cols == 3) {
      iPrint('void selfScaleAdjoint(num scale) {');
      iPush();
      iPrint('num m00 = ${Access(0, 0)};');
      iPrint('num m01 = ${Access(0, 1)};');
      iPrint('num m02 = ${Access(0, 2)};');
      iPrint('num m10 = ${Access(1, 0)};');
      iPrint('num m11 = ${Access(1, 1)};');
      iPrint('num m12 = ${Access(1, 2)};');
      iPrint('num m20 = ${Access(2, 0)};');
      iPrint('num m21 = ${Access(2, 1)};');
      iPrint('num m22 = ${Access(2, 2)};');
      iPrint('${Access(0, 0)} = (m11 * m22 - m12 * m21) * scale;');
      iPrint('${Access(1, 0)} = (m12 * m20 - m10 * m22) * scale;');
      iPrint('${Access(2, 0)} = (m10 * m21 - m11 * m20) * scale;');
      
      iPrint('${Access(0, 1)} = (m02 * m21 - m01 * m22) * scale;');
      iPrint('${Access(1, 1)} = (m00 * m22 - m02 * m20) * scale;');
      iPrint('${Access(2, 1)} = (m01 * m20 - m00 * m21) * scale;');
      
      iPrint('${Access(0, 2)} = (m01 * m12 - m02 * m11) * scale;');
      iPrint('${Access(1, 2)} = (m02 * m10 - m00 * m12) * scale;');
      iPrint('${Access(2, 2)} = (m00 * m00 - m01 * m10) * scale;');
      iPop();
      iPrint('}');
    }
    
    if (cols == 4) {
      iPrint('void selfScaleAdjoint(num scale) {');
      iPush();
      iPrint('\/\/ Adapted from code by Richard Carling.');
      iPrint('num a1 = ${Access(0,0)};');
      iPrint('num b1 = ${Access(0,1)};');
      iPrint('num c1 = ${Access(0,2)};');
      iPrint('num d1 = ${Access(0,3)};');

      iPrint('num a2 = ${Access(1,0)};');
      iPrint('num b2 = ${Access(1,1)};');
      iPrint('num c2 = ${Access(1,2)};');
      iPrint('num d2 = ${Access(1,3)};');

      iPrint('num a3 = ${Access(2,0)};');
      iPrint('num b3 = ${Access(2,1)};');
      iPrint('num c3 = ${Access(2,2)};');
      iPrint('num d3 = ${Access(2,3)};');

      iPrint('num a4 = ${Access(3,0)};');
      iPrint('num b4 = ${Access(3,1)};');
      iPrint('num c4 = ${Access(3,2)};');
      iPrint('num d4 = ${Access(3,3)};');
      
      iPrint('${Access(0,0)}  =   ${generateInlineDet3( 'b2', 'b3', 'b4', 'c2', 'c3', 'c4', 'd2', 'd3', 'd4')} * scale;');
      iPrint('${Access(1,0)}  = - ${generateInlineDet3( 'a2', 'a3', 'a4', 'c2', 'c3', 'c4', 'd2', 'd3', 'd4')} * scale;');
      iPrint('${Access(2,0)}  =   ${generateInlineDet3( 'a2', 'a3', 'a4', 'b2', 'b3', 'b4', 'd2', 'd3', 'd4')} * scale;');
      iPrint('${Access(3,0)}  = - ${generateInlineDet3( 'a2', 'a3', 'a4', 'b2', 'b3', 'b4', 'c2', 'c3', 'c4')} * scale;');
          
      iPrint('${Access(0,1)}  = - ${generateInlineDet3( 'b1', 'b3', 'b4', 'c1', 'c3', 'c4', 'd1', 'd3', 'd4')} * scale;');
      iPrint('${Access(1,1)}  =   ${generateInlineDet3( 'a1', 'a3', 'a4', 'c1', 'c3', 'c4', 'd1', 'd3', 'd4')} * scale;');
      iPrint('${Access(2,1)}  = - ${generateInlineDet3( 'a1', 'a3', 'a4', 'b1', 'b3', 'b4', 'd1', 'd3', 'd4')} * scale;');
      iPrint('${Access(3,1)}  =   ${generateInlineDet3( 'a1', 'a3', 'a4', 'b1', 'b3', 'b4', 'c1', 'c3', 'c4')} * scale;');
          
      iPrint('${Access(0,2)}  =   ${generateInlineDet3( 'b1', 'b2', 'b4', 'c1', 'c2', 'c4', 'd1', 'd2', 'd4')} * scale;');
      iPrint('${Access(1,2)}  = - ${generateInlineDet3( 'a1', 'a2', 'a4', 'c1', 'c2', 'c4', 'd1', 'd2', 'd4')} * scale;');
      iPrint('${Access(2,2)}  =   ${generateInlineDet3( 'a1', 'a2', 'a4', 'b1', 'b2', 'b4', 'd1', 'd2', 'd4')} * scale;');
      iPrint('${Access(3,2)}  = - ${generateInlineDet3( 'a1', 'a2', 'a4', 'b1', 'b2', 'b4', 'c1', 'c2', 'c4')} * scale;');
          
      iPrint('${Access(0,3)}  = - ${generateInlineDet3( 'b1', 'b2', 'b3', 'c1', 'c2', 'c3', 'd1', 'd2', 'd3')} * scale;');
      iPrint('${Access(1,3)}  =   ${generateInlineDet3( 'a1', 'a2', 'a3', 'c1', 'c2', 'c3', 'd1', 'd2', 'd3')} * scale;');
      iPrint('${Access(2,3)}  = - ${generateInlineDet3( 'a1', 'a2', 'a3', 'b1', 'b2', 'b3', 'd1', 'd2', 'd3')} * scale;');
      iPrint('${Access(3,3)}  =   ${generateInlineDet3( 'a1', 'a2', 'a3', 'b1', 'b2', 'b3', 'c1', 'c2', 'c3')} * scale;');
      iPop();
      iPrint('}');
    }
  }
  
  void generateCopy() {
    iPrint('$matType copy() {');
    iPush();
    iPrint('return new ${matType}.copy(this);');
    iPop();
    iPrint('}');
    
    iPrint('void copyIntoMatrix($matType arg) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('arg.${Access(j,i)} = ${Access(j,i)};');
      }
    }
    iPop();
    iPrint('}');
    
    iPrint('void copyFromMatrix($matType arg) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j,i)} = arg.${Access(j,i)};');
      }
    }
    iPop();
    iPrint('}');
  }
  
  void generateSelfOp(String name, String op) {
    iPrint('$matType self$name($matType o) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j,i)} = ${Access(j,i)} $op o.${Access(j,i)};');
      }
    }
    iPrint('return this;');
    iPop();
    iPrint('}');
  }
  
  void generateSelfScalarOp(String name, String op) {
    iPrint('$matType self$name(num o) {');
    iPush();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j,i)} = ${Access(j,i)} $op o;');
      }
    }
    iPrint('return this;');
    iPop();
    iPrint('}');
  }
  
  void generateSelfNegate() {
    iPrint('$matType selfNegate() {');
    iPush();
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        iPrint('${Access(j,i)} = -${Access(j,i)};');
      }
    }
    iPrint('return this;');
    iPop();
    iPrint('}');
  }
  
  generateSelfMultiplyMatrix() {
    if (rows != cols) {
      // Only generate this for square matrices
      return;
    }
    iPrint('$matType selfMultiply($matType arg) {');
    iPush(); 
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        iPrint('final num m$i$j = ${Access(i, j)};');
      }
    }
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        iPrint('final num n$i$j = arg.${Access(i, j)};');
      }
    }
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        String r = '';
        for (int k = 0; k < rows; k++) {
          if (k != 0) {
            r = '$r +';
          }
          r = '$r (m$i$k * n$k$j)';
          
        }
        iPrint('${Access(i, j)} = $r;');
      }
      
    }
    iPrint('return this;');
    iPop();
    iPrint('}');
  }
  
  generateSelfTransposeMultiplyMatrix() {
    if (rows != cols) {
      // Only generate this for square matrices
      return;
    }
    iPrint('$matType selfTransposeMultiply($matType arg) {');
    iPush(); 
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        iPrint('num m$i$j = ${Access(j, i)};');
      }
    }
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        String r = '';
        for (int k = 0; k < rows; k++) {
          if (k != 0) {
            r = '$r +';
          }
          r = '$r (m$i$k * arg.${Access(k, j)})';
          
        }
        iPrint('${Access(i, j)} = $r;');
      }
      
    }
    iPrint('return this;');
    iPop();
    iPrint('}');
  }
  
  generateSelfMultiplyTransposeMatrix() {
    if (rows != cols) {
      // Only generate this for square matrices
      return;
    }
    iPrint('$matType selfMultiplyTranpose($matType arg) {');
    iPush(); 
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        iPrint('num m$i$j = ${Access(i, j)};');
      }
    }
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        String r = '';
        for (int k = 0; k < rows; k++) {
          if (k != 0) {
            r = '$r +';
          }
          r = '$r (m$i$k * arg.${Access(j, k)})';
          
        }
        iPrint('${Access(i, j)} = $r;');
      }
      
    }
    iPrint('return this;');
    iPop();
    iPrint('}');
  }
  /*
  String generateInlineDot(String rowPrefix, int row, String col, int len) {
    String r = '';
    for (int i = 0; i < len; i++) {
      if (i != 0) {
        r = '$r +'; 
      }
      r = '$r (${rowPrefix}.${Access(row, i)} * ${col}.${AccessV(i)})';
    }
    return r;
  }
  */
  void generateTransforms() {
    if (rows != cols) {
      return;
    }
    
    if (rows == 2) {
      iPrint('vec2 transformDirect(vec2 arg) {');
      iPush();
      iPrint('num x_ = ${generateInlineDot('this', 0, 'arg', 2)};');
      iPrint('num y_ = ${generateInlineDot('this', 1, 'arg', 2)};');
      iPrint('arg.x = x_;');
      iPrint('arg.y = y_;');
      iPrint('return arg;');
      iPop();
      iPrint('}');
      iPrint('vec2 transform(vec2 arg) {');
      iPush();
      iPrint('vec2 d = arg.copy();');
      iPrint('return transformDirect(d);');
      iPop();
      iPrint('}');
    }
    
    if (rows == 3) {
      iPrint('vec3 transformDirect(vec3 arg) {');
      iPush();
      iPrint('num x_ = ${generateInlineDot('this', 0, 'arg', 3)};');
      iPrint('num y_ = ${generateInlineDot('this', 1, 'arg', 3)};');
      iPrint('num z_ = ${generateInlineDot('this', 2, 'arg', 3)};');
      iPrint('arg.x = x_;');
      iPrint('arg.y = y_;');
      iPrint('arg.z = z_;');
      iPrint('return arg;');
      iPop();
      iPrint('}');
      iPrint('vec3 transform(vec3 arg) {');
      iPush();
      iPrint('vec3 d = arg.copy();');
      iPrint('return transformDirect(d);');
      iPop();
      iPrint('}');
    }
    
    if (rows == 4) {
      iPrint('vec3 transformDirect3(vec3 arg) {');
      iPush();
      iPrint('num x_ = ${generateInlineDot('this', 0, 'arg', 3)} + ${Access(0, 3)};');
      iPrint('num y_ = ${generateInlineDot('this', 1, 'arg', 3)} + ${Access(1, 3)};');
      iPrint('num z_ = ${generateInlineDot('this', 2, 'arg', 3)} + ${Access(2, 3)};');
      iPrint('arg.x = x_;');
      iPrint('arg.y = y_;');
      iPrint('arg.z = z_;');
      iPrint('return arg;');
      iPop();
      iPrint('}');
      iPrint('vec3 transform3(vec3 arg) {');
      iPush();
      iPrint('vec3 d = arg.copy();');
      iPrint('return transformDirect3(d);');
      iPop();
      iPrint('}');
      
      iPrint('vec4 transformDirect(vec4 arg) {');
      iPush();
      iPrint('num x_ = ${generateInlineDot('this', 0, 'arg', 3)};');
      iPrint('num y_ = ${generateInlineDot('this', 1, 'arg', 3)};');
      iPrint('num z_ = ${generateInlineDot('this', 2, 'arg', 3)};');
      iPrint('num w_ = ${generateInlineDot('this', 3, 'arg', 3)};');
      iPrint('arg.x = x_;');
      iPrint('arg.y = y_;');
      iPrint('arg.z = z_;');
      iPrint('arg.w = w_;');
      iPrint('return arg;');
      iPop();
      iPrint('}');
      iPrint('vec4 transform(vec4 arg) {');
      iPush();
      iPrint('vec4 d = arg.copy();');
      iPrint('return transformDirect(d);');
      iPop();
      iPrint('}');
    }
  }
  
  void generateBuffer() {
    iPrint('\/\/\/ Copies [this] into [array] starting at [offset].');
    iPrint('void copyIntoArray(${floatArrayType} array, [int offset=0]) {');
    iPush();
    iPrint('int i = offset;');
    for (int j = 0; j < cols; j++) {
      for (int i = 0; i < rows; i++) {
        iPrint('array[i] = ${Access(i,j)};');
        iPrint('i++;');
      }
    }
    iPop();
    iPrint('}');
    iPrint('\/\/\/ Returns a copy of [this] as a [${floatArrayType}].');
    iPrint('${floatArrayType} copyAsArray() {');
    iPush();
    iPrint('${floatArrayType} array = new ${floatArrayType}(${rows * cols});');
    iPrint('int i = 0;');
    for (int j = 0; j < cols; j++) {
      for (int i = 0; i < rows; i++) {
        iPrint('array[i] = ${Access(i,j)};');
        iPrint('i++;');
      }
    }
    iPrint('return array;');
    iPop();
    iPrint('}');
    iPrint('\/\/\/ Copies elements from [array] into [this] starting at [offset].');
    iPrint('void copyFromArray(${floatArrayType} array, [int offset=0]) {');
    iPush();
    iPrint('int i = offset;');
    for (int j = 0; j < cols; j++) {
      for (int i = 0; i < rows; i++) {
        iPrint('${Access(i,j)} = array[i];');
        iPrint('i++;');
      }
    }
    iPop();
    iPrint('}');
  }
  
  void generate() {
    writeLicense();
    generatePrologue();
    generateConstructors();
    generateToString();
    generateRowColProperties();
    generateIndexOperator();
    generateAssignIndexOperator();
    generateRowGetterSetters();
    generateRowHelpers();
    generateColumnHelpers();
    generateMult();
    generateOp('+');
    generateOp('-');
    generateNegate();
    generateTranspose();
    generateAbsolute();
    generateDeterminant();
    generateTrace();
    generateInfinityNorm();
    generateError();
    generateTranslate();
    generateRotation();
    generateInvert();
    generateSetRotation();
    generateAdjugate();
    generateCopy();
    generateSelfOp('Add', '+');
    generateSelfOp('Sub', '-');
    generateSelfScalarOp('Scale', '*');
    generateSelfNegate();
    generateSelfMultiplyMatrix();
    generateSelfTransposeMultiplyMatrix();
    generateSelfMultiplyTransposeMatrix();
    generateTransforms();
    generateBuffer();
    generateEpilogue();
  }
}

void main() {
  String htmlBasePath = 'lib/html';
  String consoleBasePath = 'lib/console';
  var f = null;
  var o;
  f = new File('${htmlBasePath}/matrix2x2_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.rows = 2;
    mg.cols = 2;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  f = new File('${htmlBasePath}/matrix2x3_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.cols = 2;
    mg.rows = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${htmlBasePath}/matrix2x4_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.cols = 2;
    mg.rows = 4;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${htmlBasePath}/matrix3x2_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.rows = 2;
    mg.cols = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${htmlBasePath}/matrix3x3_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.rows = 3;
    mg.cols = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${htmlBasePath}/matrix3x4_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.rows = 4;
    mg.cols = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${htmlBasePath}/matrix4x2_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.rows = 2;
    mg.cols = 4;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${htmlBasePath}/matrix4x3_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.cols = 4;
    mg.rows = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });

  f = new File('${htmlBasePath}/matrix4x4_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32Array';
    mg.rows = 4;
    mg.cols = 4;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${consoleBasePath}/matrix2x2_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.rows = 2;
    mg.cols = 2;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  f = new File('${consoleBasePath}/matrix2x3_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.cols = 2;
    mg.rows = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${consoleBasePath}/matrix2x4_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.cols = 2;
    mg.rows = 4;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${consoleBasePath}/matrix3x2_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.rows = 2;
    mg.cols = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${consoleBasePath}/matrix3x3_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.rows = 3;
    mg.cols = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${consoleBasePath}/matrix3x4_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.rows = 4;
    mg.cols = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${consoleBasePath}/matrix4x2_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.rows = 2;
    mg.cols = 4;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
  
  f = new File('${consoleBasePath}/matrix4x3_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.cols = 4;
    mg.rows = 3;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });

  f = new File('${consoleBasePath}/matrix4x4_gen.dart');
  o = f.open(FileMode.WRITE);
  o.then((opened) {
    print('opened');
    MatrixGen mg = new MatrixGen();
    mg.floatArrayType = 'Float32List';
    mg.rows = 4;
    mg.cols = 4;
    mg.out = opened;
    mg.generate();
    opened.closeSync();
  });
}