Program Soliter;
type
  box = record
    mine: boolean := False;
    chek: boolean := False;
    show: char    := ' ';
    flag: boolean := False;
  public
    constructor Create(mine: boolean; check: boolean; show: char);
    begin
      self.mine := mine;
      self.chek := check;
      self.show := show;
    end;
  end;
var
  mines, xF,yF, x,y: integer; 
    // количество мин
    // размеры поля
    // выбранная клетка нужно в Ask(), но ругается, если объявить в начале Ask()
  EndGame,  TrueFlag, gametype, gamemode: byte;
    // EndGame  : 0 = играем дальше, 1 = победа, 2 = подорвался, 3 = ушёл
    // TrueFlag : означает количество совпадений флагов и мин
    // gametype : как выглядит игра, какие правила подключать (3/4/6)
    // gamemode : режим который сейчас выбрал игрок (мины/флаги)
  Field: array [,] of box;
    // основной элемент, в котором отражены все клетки в виде матрицы

// ссылки на функции
Procedure Click (ix, iy: integer);      forward;
Procedure Check (ix, iy: integer);      forward;
Procedure BasicSet ();                  forward;


// подсчёт мин вокруг
Function LookAround3(ix, iy: integer): integer;
begin
// лишняя безопастность
  if (((0 < ix)and(ix < xF)) and ((0 < iy)and(iy < yF))) then
  begin
  // around представляет собой подсчёт мин и вычет флагов вокруг точки
  var around : integer := 0;
  if ((ix+iy) mod 2 = 1) then
  // нечётные диагонали
  begin
    if Field[ix-1, iy].mine then // посмотреть под 
      around += 1;
    if Field[ix-1, iy].flag then
      around -= 1;
  end
  else
  // чётные диагонали
  begin
    if Field[ix+1, iy].mine then // посмотреть над
      around += 1;
    if Field[ix+1, iy].flag then
      around -= 1;
  end;
      
// неважно чётная или нечётная нужно посмотреть соседей
  if Field[ix, iy-1].mine then   // посмотреть слева 
    around += 1;
  if Field[ix, iy-1].flag then
    around -= 1;
  if Field[ix, iy+1].mine then   // посмотреть справа 
    around += 1;
  if Field[ix, iy+1].flag then
    around -= 1;
  
  Result := around;
  end;
end;
Function LookAround4(ix, iy: integer): integer;
begin
  var around : integer := 0;
  for var i := ix-1 to ix+1 do
    for var k := iy-1 to iy+1 do
    begin
      if Field[i, k].mine then
        around += 1; // рядом мина
      if Field[i, k].flag then
        around -= 1; // рядом флаг
    end;
  Result := around;
end;
Function LookAround6(ix, iy: integer): integer;
begin
  var around : integer := 0;
  for var i := ix-1 to ix+1 do
    for var k := iy-1 to iy+1 do
    begin
      // ненужные клетки на главной диагонали
      if not (ix-i = iy-k) then
      begin
        if Field[i,k].mine then
          around += 1;
        if Field[i,k].flag then
          around -= 1;
      end;
    end;
  Result := around;
end;
Function LookAround (ix, iy: integer): integer;
begin
  case gametype of
    3: Result := LookAround3(ix,iy);
    4: Result := LookAround4(ix,iy);
    6: Result := LookAround6(ix,iy);
  end;
end;

// отрисовка при проигрыше
Procedure DrawLose3(a: array [,] of box);
begin
// напечатать первой строкой ось Y
  write(' __// ');
  for var p := 1 to yF - 1 do 
  begin
    write(p: 3); write('|');
  end;
  writeln();
  
// лишняя строка для отрисовки сетки
  write('   |> ');
  for var k := 0 to Round((yF)/2)-2 do
    write('>><<', '----');
  writeln();
  
  var Xaxis := 1; // счёчик оси в начало
  var flags := 0; // актуальный счётчик флагов
  for var i := 1 to xF-1 do
  begin
    
// ось X
    write(i:3, '<< ');
    
    for var k := 1 to yF-1 do
    begin
      
// откры диагональ чётная
      if ((i+k) mod 2 = 1) then 
        write('\')
      // диагональ нечётная
      else
        write('/');
    
    // на клетке мина
      if Field[i,k].mine then
      // с флагом
        if Field[i,k].flag then
          write('X^')
      // без флага
        else
          write('X ')
      else
    // а клетке нет мины, но есть флаг
        if Field[i,k].flag then
          write(' ^')
    // ни мины, ни флага
      else
        write(' ', Field[i,k].show);
      
// зав диагональ чётная
      if ((i+k) mod 2 = 1) then 
        write('/')
      // диагональ нечётная
      else
        write('\');
    end;
    
    writeln(); write('   |><');
    // дорисовать клеточки
    if (i mod 2 = 0) then
      for var k := 0 to Round((yF)/2)-2 do
        write('>><<', '----')
    else
      for var k := 0 to Round((yF)/2)-2 do
        write('----', '>><<');
    
    writeln(); Xaxis += 1;
  end;
  
  write(' Cчётчик мин = ', mines - flags);
  if mines - flags < 0 then write(' где-то флаг неверно стоит');
  case gamemode of
    0: writeln(' X');
    1: writeln(' ^'); 
  end;
end;
Procedure DrawLose4(a: array [,] of box);
begin
  writeln();
// нарисовать ось 
  var Xaxis := 1; // сделать счёчик нулём
  write(' __//');
  for var p := 1 to yF - 1 do // напечатать первый ось х
  begin
    write(p:3); write('|');
  end;
  writeln();
  
// нарисовать основу
  for var i := 1 to xF - 1 do
  begin
    write(Xaxis: 3); write('||'); // печать строки
    for var k := 1 to yF - 1 do
    begin
      if Field[i, k].flag then
        //     1
        write('^')
      else
            // 1
        write(' ');
      if Field[i, k].mine then
            // 2          3
        write('X', Field[i, k].show, '|')
      else  // используется, Field.show потому что нужно отобразить картинку в целом
            //            2          3
        write('', Field[i, k].show, ' |');
    end;
  // дорисовать клеточки
    writeln(); write('   |');
    for var k := 1 to yF-1 do
      write('+---');
    write('+');
    writeln(); Xaxis += 1;
  end;
end;
Procedure DrawLose6(a: array [,] of box);
begin
// напечатать первой строкой ось Y
  var space := 0;  // отступ для новой строки
  write('   \');
  for var p := 1 to yF-1 do
  begin
    write(p: 3); write('\');
  end;
  writeln();
  
// лишняя строка для отрисовки сетки
  for var p := 0 to space+3 do
    write(' '); 
  for var p := 0 to yF-1 do
    write('\_/ ');
  writeln();
  
  for var i := 1 to xF-1 do
  begin
// ось X
    for var p := 0 to space do
      write(' '); 
    write(i:3, ' ');
    for var k := 1 to yF-1 do
    begin
      write('|');
      
      // на клетке мина
        if Field[i,k].mine then
        // с флагом
          if Field[i,k].flag then
            write('X^\')
        // без флага
          else
            write('X  ')
        else
      // а клетке нет мины, но есть флаг
          if Field[i,k].flag then
            write(' ^\')
      // ни мины, ни флага
        else
          write(' ', Field[i,k].show, ' ')
    end;
    
    writeln('|');
    // дорисовать клеточки
    for var p := 0 to space+4 do
      write(' ');
    for var p := 0 to yF-1 do
      write(' \_/');
    writeln(); space += 2; 
  end;
end;
Procedure DrawLose (a: array [,] of box);
begin
  case gametype of
    3: DrawLose3(a);
    4: DrawLose4(a);
    6: DrawLose6(a);
  end;
end;

// отрисовка при игре
Procedure DrawGame3(a: array [,] of box);
begin
  // напечатать первой строкой ось х
  write(' X\\Y/');
  for var p := 1 to yF - 1 do 
  begin
    write(p: 3); write('|');
  end;
  writeln();
  // напечатать первую дорисовки до треугольника
  write('   |> ');
  for var k := 0 to Round((yF)/2)-2 do
    write('>><<', '----');
  writeln();
  
  var Xaxis := 1; // счёчик оси в начало
  var flags := 0; // актуальный счётчик флагов
  for var i := 1 to xF - 1 do
  begin
    write(Xaxis: 3); write('<< ');         // печать строки
    for var k := 1 to yF - 1 do
    begin
      if Field[i, k].flag then flags += 1;
      if Field[i, k].chek and not Field[i, k].flag then
      // i mod 2 = 0
        if (i mod 2 = 0) then
        // around < 0
          if (LookAround(i, k) < 0) then // флагов больше, счётчик отрицательный
          // сторона сверху 
            if ((i+k) mod 2 = 1) then
                  //            12
              write('\', LookAround(i, k), '/')
          // сторона снизу
            else
              write('/', LookAround(i, k), '\')
        // around >= 0
          else 
          // around = 0
            if (LookAround(i, k) = 0) then
            // сторона сверху
              if ((i+k) mod 2 = 1) then
                    //  12
                write('\ ./')
              else
                write('/ .\')
          // around > 0
            else
            // сторона сниху
              if ((i+k) mod 2 = 1) then
                    //  1           2
                write('\ ',  LookAround(i, k), '/')
            // сторона сверху
              else
                write('/ ',  LookAround(i, k), '\')
      // i mod 2 = 1
        else
        // around < 0
          if (LookAround(i, k) < 0) then
          // сторона снизу
            if ((i+k) mod 2 = 1) then
                  //            12
              write('\', LookAround(i,k),'/')
            else
          // сторона сверху
              write('/', LookAround(i,k),'\')
        // around >= 0
          else
            // around = 0
            if (LookAround(i, k) = 0) then
              if ((i+k) mod 2 = 1) then
                    //  12
                write('\ ./')
              else
                write('/ .\')
            // around > 0
            else
              if ((i+k) mod 2 = 1) then
                    //  1          2
                write('\ ', LookAround(i, k), '/')
              else
                write('/ ', LookAround(i, k), '\')
    // не было проверено или флаг, то есть тут стоит флаг
      else
      // i mod 2 = 0
        if (i mod 2 = 0) then
        // флаг
          if Field[i, k].flag then
            if ((i+k) mod 2 = 1) then
                  //  12
              write('\^ /')
            else
              write('/^ \')
          // нет флага
          else
            if ((i+k) mod 2 = 1) then
              write('\  /')
                  //  12
            else
              write('/  \')
      // i mod 2 = 1
        else
        // флаг
          if Field[i, k].flag then
            if ((i+k) mod 2 = 1) then
                  //  12 
              write('\^ /')
            else
              write('/^ \')
        // нет флага
          else
            if ((i+k) mod 2 = 1) then
                  //  12
              write('\  /')
            else
              write('/  \');
    end;
    
    writeln(); write('   |> ');
        // дорисовать клеточки
      if (i mod 2 = 0) then
        for var k := 0 to Round((yF)/2)-2 do
         write('>><<', '----')
      else
        for var k := 0 to Round((yF)/2)-2 do
          write('----', '>><<');
    
    writeln(); Xaxis += 1;
  end;
  
  write(' Cчётчик мин = ', mines - flags);
  if mines - flags < 0 then write(' где-то флаг неверно стоит');
  case gamemode of
    0: writeln(' X');
    1: writeln(' ^'); 
  end;
end;
procedure DrawGame4(a: array [,] of box);
begin
    
  var Xaxis := 1; // сделать счёчик нулём
  write(' X\Y/');
  for var p := 1 to yF - 1 do // напечатать первой строкой ось х
  begin
    write(p: 3); write('|');
  end;
  
  writeln(); write('   |');
  for var k := 1 to yF-1 do
    write('+---');
  writeln('+');
  
  var flags := 0;
  for var i := 1 to xF - 1 do
  begin
    write(Xaxis: 3); write('||');         // печать строки
    for var k := 1 to yF - 1 do
    begin
      if Field[i, k].flag then flags += 1;
      if Field[i, k].chek and not Field[i, k].flag then
        if (LookAround(i, k) < 0) then
          if (LookAround(i, k) = 0) then
                // 12    3
            write(' .', ' ')
          else
                //            12          3
            write('',  LookAround(i, k), ' ')
        else // LookAround(x,y), потому что требуется отобразить конкретные значения клеток
        if LookAround(i, k) = 0 then
              // 12    3
          write(' .', ' ')
        else
              // 1           2           3
          write(' ',  LookAround(i, k), ' ')
      else
      if Field[i, k].flag then
            // 123
        write('^\ ')
      else
            // 123
        write('   ');
      write('|');
      
    end;
    // дорисовать клеточки
    writeln(); write('   |');
    for var k := 1 to yF-1 do
      write('+---');
    write('+');
    writeln(); Xaxis += 1;
  end;
  
  write(' Cчётчик мин = ', mines - flags);
  if mines - flags < 0 then write(' где-то флаг неверно стоит');
  case gamemode of
    0: writeln(' X');
    1: writeln(' ^'); 
  end;

end;
Procedure DrawGame6(a: array [,] of box);
begin
  
// напечатать первой строкой ось Y
  var space := 0;  // отступ для новой строки
  write('   \');
  for var p := 1 to yF-1 do
  begin
    write(p: 3); write('\');
  end;
  writeln();
  
// лишняя строка для отрисовки сетки
  for var p := 0 to space+3 do
    write(' '); 
  for var p := 0 to yF-1 do
    write('\_/ ');
  writeln();
  
  var flags := 0;     // актуальный счётчик флагов
  for var i := 1 to xF-1 do
  begin
// ось X
    for var p := 0 to space do
      write(' '); 
    write(i:3, ' ');
    for var k := 1 to yF-1 do
    begin
      write('|');
      
      if Field[i,k].chek then
      // на клетке мина
        if Field[i,k].mine then
        // с флагом
          if Field[i,k].flag then
          begin write('X^\'); flags += 1 end
        // без флага
          else
            write('X  ')
        else
      // а клетке нет мины, но есть флаг
          if Field[i,k].flag then
          begin write(' ^\'); flags += 1 end
      // ни мины, ни флага
        else
          if not (LookAround(i,k) = 0) then
          // Field() = 'n'
            write(' ', LookAround(i,k), ' ')
          else
          // Field() = '.'
            write(' . ')
      else
        write('   ');
    end;
    
    writeln('|');
    // дорисовать клеточки
  for var p := 0 to space+4 do
    write(' ');
  for var p := 0 to yF-1 do
    write(' \_/');
  writeln(); space += 2; 
  end;
  
  write(' Cчётчик мин = ', mines - flags);
  if mines - flags < 0 then write(' где-то флаг неверно стоит ');
  case gamemode of
    0: writeln('X');
    1: writeln('^'); 
  end;
end;
Procedure DrawGame (a: array [,] of box);
begin
  case gametype of
    3: DrawGame3(a);
    4: DrawGame4(a);
    6: DrawGame6(a);
  end;
end;

// блок для ссылок вперёд
// Нажал на это или нажал на клетку без соседней мины
Procedure Click3(ix, iy: integer);
begin
  // Проверка координат на нахождение в границах
  if ((0 < ix) and (ix < xF) or (0 < iy) and (iy < yF)) then
    if not Field[ix, iy].chek then
    begin
    // не проверено -> узнать, что написано на клетке
      Check(ix, iy);
      if Field[ix, iy].mine = True then
      // мина есть -> подорвался
        EndGame := 2
      else  
      // мины нет -> вокруг пусто -> нажать окружающих        
        if (Field[ix, iy].show = '.') then
        begin
          // сначала право лево
          Click(ix, iy-1);
          Click(ix, iy+1);
          // если надо верх если надо вниз
          if ((ix+iy) mod 2 = 1) then
            Click(ix-1, iy)
          else
            Click(ix+1, iy);
        end;
    end;
    // координаты были проверены или за гранью  
end;
procedure Click4(ix, iy: integer);
begin
    // Проверка координат на нахождение в границах
  if ((0 < ix) and (ix < xF) or (0 < iy) and (iy < yF)) then
    if not Field[ix, iy].chek then
    begin
        // узать что написано на клетке
      Check(ix, iy);
        // узнать про мину
      if Field[ix, iy].mine = True then
      // мина есть подорвался
        EndGame := 2
      else
      // мины нет если вокруг пусто позвать окружающих
        for var i := ix - 1 to ix + 1 do
          for var k := iy - 1 to iy + 1 do
            if (Field[ix, iy].show = '.') then
              Click(i, k);
    end
    // координаты были проверены или за гранью
end;
Procedure Click6(ix, iy: integer);
begin
    // Проверка координат на нахождение в границах
  if ((0 < ix) and (ix < xF) or (0 < iy) and (iy < yF)) then
    if not Field[ix, iy].chek then
    begin
        // узать что написано на клетке
      Check(ix, iy);
        // узнать про мину
      if Field[ix, iy].mine = True then
      // мина есть подорвался
        EndGame := 2
      else
      // мины нет если вокруг пусто позвать окружающих
        for var i := ix - 1 to ix + 1 do
          for var k := iy - 1 to iy + 1 do
            if (Field[ix, iy].show = '.') then
              // мин у соседей нет
              if not (ix-i = iy-k) then
                // все кроме главной диагонали
                Click(i, k);
    end
    // координаты были проверены или за гранью

end;
Procedure Click (ix, iy: integer);
begin
  case gametype of
    3: Click3(ix,iy);
    4: Click4(ix,iy);
    6: Click6(ix,iy);
  end;
end;

// Посмотреть место в поисках мины
Procedure Check3(ix, iy: integer);
begin
// проверяем соседей, если там нет мины и пусто вокруг
  if not Field[ix, iy].mine then
    case LookAround(ix, iy) of
    // запишем символы в клетки для отображения
      -3: Field[ix, iy].show := '3';
      -2: Field[ix, iy].show := '2';
      -1: Field[ix, iy].show := '1';
      0 : Field[ix, iy].show := '.';
      1 : Field[ix, iy].show := '1';
      2 : Field[ix, iy].show := '2';
      3 : Field[ix, iy].show := '3';
      else write('Ошибка подсчёта мин');
    end;
  Field[ix, iy].chek := True;  
end;
procedure Check4(ix, iy: integer);
begin
  // проверяем соседей, если там нет мины и пусто вокруг
  if not Field[ix, iy].mine then
    case LookAround(ix, iy) of
    // запишем символы в клетки для отображения
      -9: ; // подсчёт ведётся в девяти клетках
      -8: Field[ix, iy].show := '8';
      -7: Field[ix, iy].show := '7';
      -6: Field[ix, iy].show := '6';
      -5: Field[ix, iy].show := '5';
      -4: Field[ix, iy].show := '4';
      -3: Field[ix, iy].show := '3';
      -2: Field[ix, iy].show := '2';
      -1: Field[ix, iy].show := '1';
      0 : Field[ix, iy].show := '.';
      1 : Field[ix, iy].show := '1';
      2 : Field[ix, iy].show := '2';
      3 : Field[ix, iy].show := '3';
      4 : Field[ix, iy].show := '4';
      5 : Field[ix, iy].show := '5';
      6 : Field[ix, iy].show := '6';
      7 : Field[ix, iy].show := '7';
      8 : Field[ix, iy].show := '8';
      9 : ;
    else write('Ошибка подсчёта мин');
    end;
  Field[ix, iy].chek := True;
end;
Procedure Check6(ix, iy: integer);
begin
  // проверяем соседей, если там нет мины и пусто вокруг
  if not Field[ix, iy].mine then
    case LookAround(ix, iy) of
    // запишем символы в клетки для отображения
      -6: Field[ix, iy].show := '6';
      -5: Field[ix, iy].show := '5';
      -4: Field[ix, iy].show := '4';
      -3: Field[ix, iy].show := '3';
      -2: Field[ix, iy].show := '2';
      -1: Field[ix, iy].show := '1';
      0 : Field[ix, iy].show := '.';
      1 : Field[ix, iy].show := '1';
      2 : Field[ix, iy].show := '2';
      3 : Field[ix, iy].show := '3';
      4 : Field[ix, iy].show := '4';
      5 : Field[ix, iy].show := '5';
      6 : Field[ix, iy].show := '6';
    else write('Ошибка подсчёта мин');
    end;
  Field[ix, iy].chek := True;
end;
Procedure Check (ix, iy: integer);
begin
  case gametype of
    3: Check3(ix,iy);
    4: Check4(ix,iy);
    6: Check6(ix,iy);
  end;
end;

//\\ Создать поле
function BuildTiles(ix, iy: integer): array [,] of box;
begin
  var NewF: array [,] of box := new box[ix + 1, iy + 1];
  for var i := 0 to ix do
    for var k := 0 to iy do
    begin
      NewF[i, k] := new box(False, False, ' ');
      if ((i = 0) or (i = ix) or (k = 0) or (k = iy)) then
        NewF[i, k].chek := True;
    end;
  Result := NewF;
end;

//\\ Создание мин
function IniMines(InputF: array [,] of box; mines: integer): array [,] of box;
begin
  repeat
    // обход строк
    for var i := 1 to xF-1 do
    begin
      // обход столбов
      for var k := 1 to yF-1 do
      begin
        if not InputF[i, k].mine then // нет мины
          if (mines > 0) then  // мин ещё не хватает
          begin
            var s := random(10); // монеткой решим сюда ли ставить
            if (s = 0) then      // если выпало, отлично
            begin
              InputF[i, k].mine := True;  // ставим мину
              mines -= 1;           // вычитаем в общем списке мин
            end;
          end;
      end;
    end;
  until (mines = 0);
  
  // для открытия поляны
  for var i := 1+Round(xF/6) to (xF-1)-Round(xF/6) do
    for var k := 1+Round(yF/6) to (yF-1)-Round(yF/6) do
      if (LookAround(i,k) = 0) then
      begin x := i; y := k; end;
  Result := InputF;
end;

// блок начальных настроек, чтобы играть было интересно, даже, если сломаешь
Procedure BasicSet3(); 
begin
  xF := 8; yF := 11; 
  gametype := 3;
  Field := BuildTiles(xF, yF);
  mines := Round((xF-1)*(yF-1)/6);
  Field := IniMines(Field, mines);
  gamemode := 0;
  writeln('Начальные настройки:');
  writeln(' - размер = ',xF-1, 'x',yF-1,' это ', (xF-1)*(yF-1),' площадь,');
  writeln(' - мин на поле ', Round((xF-1)*(yF-1)/6));
  writeln(' - режим ', gametype);
end;
procedure BasicSet4();
begin
  xF := 8; yF := 11; 
  gametype := 4;
  Field := BuildTiles(xF, yF);
  mines := Round((xF-1)*(yF-1)/5);
  Field := IniMines(Field, mines);
  gamemode := 0;
  writeln('Начальные настройки:');
  writeln(' - размер = ',xF-1, ' ',yF-1,' это ', (xF-1)*(yF-1),' клетки(ок), ');
  writeln(' - мин ', Round((xF-1)*(yF-1)/5));
  writeln(' - режим ', gametype);
end;
Procedure BasicSet6();
begin
  xF := 8; yF := 11; 
  gametype := 6;
  Field := BuildTiles(xF, yF);
  mines := Round((xF-1)*(yF-1)/4);
  Field := IniMines(Field, mines);
  gamemode := 0;
  writeln('Начальные настройки:');
  writeln(' - размер = ',xF-1,' ',yF-1,' это ', (xF-1)*(yF-1),' клетки(ок), ');
  writeln(' - мин ', Round((xF-1)*(yF-1)/4));
  writeln(' - режим ', gametype);
end;
Procedure BasicSet ();
begin
  case gametype of
    3: BasicSet3();
    4: BasicSet4();
    6: BasicSet6();
  end;
end;

//\\ Работа с пользователским вводом
  // Ввод
procedure Ask();
begin
    // спрашиваю пока мне не понравиться ввод пользователя
  var bad: boolean := False;
  repeat
    // Вывод поля
    writeln(); DrawGame(Field);
    
    // Ввод данных
    writeln();
      // x
    while not TryRead(x) do
    begin
      if (gamemode = 1) then
      begin
        writeln(' Теперь копаешь X');
        gamemode := 0//
      end
        else
      begin
        writeln(' Теперь флаги ставишь ^');
        gamemode := 1; //
      end;
      write('Нужно ввести X ');
    end;
    if (x = 0) then // Если выход из игры
    begin
      EndGame := 3;
      bad := True;
      writeln('Очень жаль.');
      break;  // не спрашивать дальше, нужно закрыть игру
    end;
    
      // y
    while not TryRead(y) do
    begin
      if (gamemode = 1) then
      begin
        writeln('Теперь копаешь X');
        gamemode := 0//
      end
        else
      begin
        writeln('Теперь флаги ставишь ^');
        gamemode := 1; //
      end;
      write('Нужно ввести Y ');
    end;
    if (y = 0) then // Если выход из игры
    begin
      EndGame := 3;
      bad := True;
      writeln('Очень жаль.');
      break;  // не спрашивать дальше, нужно закрыть игру
    end;
    
      // Если данные подходят 
    if (((0 < x) and (x < xF) and (0 < y) and (y < yF)) 
           and ((not Field[x, y].chek) or (Field[x, y].flag))) then
      bad := True // Не было проверено
    else
      writeln(
          'Было проверено или вне границ, ',
          'попробуйте снова'); // было проверено или граница
  until bad;
    // Если это просьба проверить клетку, надо проверить
  if (EndGame = 0) then // игра не закончилась
    if (gamemode = 0) then 
      Click(x, y) // режим копания = копать выбранное
    else 
      if Field[x, y].flag then           // режим флагов
      begin
        Field[x, y].flag := False;         // флаг стоит = убрать
        Field[x, y].chek := False;         // \
      end
      else 
      begin
        Field[x, y].flag := True;          // флага нема = поставить
        Field[x, y].chek := True;          // \
      end;
    // если попал в мину
  if (EndGame = 2) then 
    writeln(' Тут была мина, проиграно.');
  // иначе просто закрываем вопрос, х у сохраняется в код, неизвестно зачем
end;

// поле к заводским настройкам
procedure ResetCheck(a: array [,] of box);
begin
  for var i := 1 to xF - 1 do
    for var k := 1 to yF - 1 do
    begin
      a[i, k].chek := False;
      a[i, k].flag := False;
      a[i, k].show := ' ';
    end;
  EndGame := 0; TrueFlag := 0;
end;

//\\ Фаза игры
procedure Game();
begin
  // ========== настройки
  var settings : byte := 5;
  writeln('Смотрите, настройки:');
  writeln(' 0 - давай мимо, ');
  writeln(' 1 - хочу другое поле, ');
  writeln(' 2 - может новые мины, ');
  writeln(' 3 - выберу вид клеток, ');
  writeln(' 4 - вернуть начальные');
  
  while not TryRead(settings) do
    write('Пожалуйста введите нормальное число от 0 до 4');
  while not (settings = 0) do
  begin
    case settings of
      // ничего
      0: ; // выход из настроек
      
      // сделать новое поле
      1:
        begin// \ 1
          writeln('Введите желаемый размер');
          read(xF, yF); xF += 1; yF += 1;
          Field := BuildTiles(xF, yF);
          // поле новое но миные --> старые надо обновить
          ResetCheck(Field);
          Field := IniMines(Field,mines);
        end;  // / 1
      
      // положить новые мины
      2: 
        begin
          ResetCheck(Field);
          writeln('Поле сейчас ', xF-1, 'х', yF-1, ' = ', (xF-1)*(yF-1),
          '. Лучше ставить мины после изменения поля');
          repeat
            writeln('Мин сейчас = ', mines,
            '. Введите желаемое количество мин ');
            writeln('Я предлагаю ', (xF-1)*(yF-1)/5);
            while not TryRead(mines) do
              writeln('Число, пажожда');
          until ((mines > 0) and (mines < Round(xF * yF / 2)));
          Field := IniMines(Field, mines);
        end;
      
      // давай выберем новый тип клеток
      3:
        begin// \ 3
          repeat
            writeln(
            'Вот какие типы сапёра есть: ',
            '3 - треугольники, ',
            '4 - квадраты, ',
            '6 - шестиугольники');
            read(gametype);
            case gametype of
              4: writeln('Выбраны квадраты');
              3: writeln('Выбраны треугольники');
              6: writeln('Выбраны шестиугольники');
            else write('Выберите из данных, пожалуйста ');
            end;
          until ((gametype = 3) or (gametype = 4) or (gametype = 6));
          // надо обновить поле и мины, чтобы если вид поля меняет информацию
          Field := BuildTiles(xF, yF);
          Field := IniMines(Field,mines);
        end;  // / 3
      //
      4: BasicSet();
        
      // если вдруг пользователь дурак
      else write('Дурак!');
      end;
      writeln(
        '0 - выход, 1 - новое поле, ',
        '2 - новые мины, 3 - вид клеток, ',
        '4 - вернуть начальные');
      while not TryRead(settings) do
        write('Пожалуйста введите нормальное число от 0 до 4');
  end;
  // ============== конец настроек
  
  // после создания нужно открыть поляну внутри
  if (x = 0) then
    for var i := 1 to xF-1 do
    begin 
      for var k := 1 to yF-1 do
        if (LookAround(i,k) = 0) then 
        begin x := i; y := k; break; end;
      if not (x = 0) then
      begin Click(x,y); break; end;
    end
  else Click(x,y);
  
  // спросить какую клетку проверить
  writeln('Играем!');
  writeln(
  'Введите x y, ',
  'либо "0", если не хотите играть, ',
  'либо "F", чтобы сменить режим');
  var move := 0;
// сновной элемент
  repeat// \\ repeat
    Ask(); move += 1;
    // проверим выиграл ли
    TrueFlag := 0;
    for var i := 1 to xF - 1 do
      for var k := 1 to yF - 1 do
        if (Field[i, k].mine and 
            Field[i, k].flag) then
          TrueFlag += 1;
    if (TrueFlag = mines) then
      EndGame := 1
  until (EndGame > 0);  // \\ while
  // EndGame: 
  // 0 ~ игра продолжается,
  // 1 ~ игра закончена победой, 
  // 2 ~ наступил на мину, 
  // 3 ~ захотел закончить
  
  // Победа!
  if EndGame = 1 then
    writeln(
    '!!Победа, а ты молодец!! ',
    'Понадобилось всего ', move, ' ходов');
  // Поражение :(
  if EndGame = 2 then
  begin
    DrawLose(Field);
    writeln('   Проиграл :(');
    writeln('  Ну ты не расстраивайся. Ещё повезёт!');
  end;
  // Заново?
    writeln(' Cыграем ещё?');
    writeln('0 - нет, 1 - да ');
  
  while not TryRead(EndGame) do // пока не получил число спрашивать
    writeln('Прошу ответить, будем играть? 0 = нет, 1 = да');
  if not (EndGame = 0) then
  begin
    ResetCheck(Field);
    x := 0;
    Game()
  end
  else
    write('Всех благ!');
end;

//\\ Программа
begin
  gametype := 6;
  BasicSet();
  Game();
end.