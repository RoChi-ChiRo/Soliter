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
    // gametype : как выглядит игра, какие правила подключать
    // gamemode : режим который сейчас выбрал игрок (мины/флаги)
  Field: array [,] of box;
    // основной элемент, в котором отражены все клетки в виде матрицы

// алгоритм подсчёта мин вокруг
function LookAround(ix, iy: integer): integer;
begin
  var around := 0; // around представляет собой подсчёт мин вокруг точки
  for var i := ix - 1 to ix + 1 do
    for var k := iy - 1 to iy + 1 do
    begin
      if Field[i, k].mine then
        around += 1; // рядом мина
      if Field[i, k].flag then
        around -= 1;    // рядом флаг
    end;
  Result := around;
end;

procedure DrawLose(a: array [,] of box);
begin
  writeln();
  var Xaxis := 1; // сделать счёчик нулём
  write(' __//');
  for var p := 1 to yF - 1 do // напечатать первый ось х
  begin
    write(p:3); write('|');
  end;
  writeln();
  
  for var i := 1 to xF - 1 do
  begin
    write(Xaxis: 3); write('||'); // печать строки
    for var k := 1 to yF - 1 do
    begin
      if Field[i, k].flag then
        //     1
        write('^')
      else
      //     1
        write(' ');
      if Field[i, k].mine then
        //     2          3
        write('X', Field[i, k].show, '|')
      else  // используется, Field.show потому что нужно отобразить картинку в целом
      //                2        3
        write('', Field[i, k].show, ' |');
    end;
    writeln(); Xaxis += 1;
  end;
end;

procedure DrawGame(a: array [,] of box);
begin
    
  var Xaxis := 1; // сделать счёчик нулём
  write(' __//');
  for var p := 1 to yF - 1 do // напечатать первой строкой ось х
  begin
    write(p: 3); write('|');
  end;
  writeln();
  
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
            //     12    3
            write(' .', ' ')
          else
          //                12         3
            write('',  LookAround(i, k), ' ')
        else // LookAround(x,y), потому что требуется отобразить конкретные значения клеток
        if LookAround(i, k) = 0 then
            //     12    3
          write(' .', ' ')
        else
        //     1           2          3
          write(' ',  LookAround(i, k), ' ')
      else
      if Field[i, k].flag then
          //     123
        write('^\ ')
      else
      //     123
        write('   ');
      write('|');
      
    end;
    writeln(); Xaxis += 1;
  end;
  
  write(' Cчётчик мин = ', mines - flags);
  if mines - flags < 0 then write(' где-то флаг неверно стоит');
  case gamemode of
    0: writeln(' X');
    1: writeln(' ^'); 
  end;

end;

Procedure BasicSet(); forward;
procedure Click(ix, iy: integer); forward;
function Check(ix, iy: integer): byte; forward;


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
    for var i := 1 to xF - 1 do
    begin
        // обход столбов
      for var k := 1 to yF - 1 do
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
  Result := InputF;
end;


//\\ Работа с пользователским вводом
  // Ввод
procedure Ask();
begin
    // спрашиваю пока мне не понравиться ввод пользователя
  var bad: boolean := False;
  repeat
    // Вывод поля
    DrawGame(Field);
    
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
        writeln('Теперь копаешь');
        gamemode := 0//
      end
        else
      begin
        writeln('Теперь флаги ставишь');
        gamemode := 1; //
      end;
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
          'попробуйте снова');               // чек и грань
  until bad;
    // Если это просьба проверить клетку, её надо проверить
  if (EndGame = 0) then // игра не закончилась
    if (gamemode = 0) then 
      Click(x, y)     // режим копания = копать выбранное
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
    writeln('Тут была мина, проиграно.');
  // иначе просто закрываем вопрос, х у сохраняется в код 
end;

  // Проверка координат на необходимость действий с ними
procedure Click(ix, iy: integer);
begin
    // Проверка координат на нахождение в границах
  if ((0 < ix) and (ix < xF) or (0 < iy) and (iy < yF)) then
    if not Field[ix, iy].chek then
    begin
        // узать что написано на клетке
      Check(ix, iy);
        // узнать про мину
      if Field[ix, iy].mine = True then
          // мина есть
      begin// подорвался
        DrawLose(Field);
        EndGame := 2;
      end
      else
      // мины нет
      // если вокруг пусто позвать окружающих
        for var i := ix - 1 to ix + 1 do
          for var k := iy - 1 to iy + 1 do
            if (Field[ix, iy].show = '.') then
              Click(i, k);
    end
    else // координаты были проверены
  else
end;

  // Посмотреть место в поисках мины
procedure Check(ix, iy: integer);
begin
  // проверяем соседей, если там нет мины и пусто вокруг
  if not Field[ix, iy].mine then
    for var i := ix - 1 to ix + 1 do
      for var k := iy - 1 to iy + 1 do
      begin
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
          0: Field[ix, iy].show := '.';
          1: Field[ix, iy].show := '1';
          2: Field[ix, iy].show := '2';
          3: Field[ix, iy].show := '3';
          4: Field[ix, iy].show := '4';
          5: Field[ix, iy].show := '5';
          6: Field[ix, iy].show := '6';
          7: Field[ix, iy].show := '7';
          8: Field[ix, iy].show := '8';
          9:;
        else write('Ошибка подсчёта мин');
        end;
      end;
  Field[ix, iy].chek := True;
end;

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
  // настройки
  var settings : byte := 4;
  writeln('Смотрите, настройки, заглянуть?');
  writeln(
    '0 - давай мимо, ',
    '1 - хочу другое поле, ',
    '2 - может новые мины, ',
    '3 - выберу вид клеток, ',
    '4 - вернуть начальные');
  
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
          Field := IniMines(Field,mines);
          settings := 2;
        end;  // / 1
      
      // положить новые мины
      2: 
        begin
          writeln('Поле сейчас ', xF-1, ' на ', yF-1,
          '. Лучше ставить мины после изменения поля');
          repeat
            writeln('Мин сейчас = ', mines,
            '. Введите желаемое количество мин ');
            read(mines);
          until ((mines > 0) and (mines < Round(xF * yF / 2)));
          Field := IniMines(Field, mines);
          settings := 0;
        end;
      
      // давай выберем новый тип клеток
      3:
        begin// \ 3
          repeat
            writeln(
            'Вот какие типы сапёра есть: ',
            '4 - квадраты, ',
            '3 - треугольники, ',
            '6 - шестиугольники');
            read(gametype);
            case gametype of
              4: writeln('Выбраны квадраты');
              3: writeln('Выбраны треугольники');
              6: writeln('Выбраны шестиугольники');
            else write('Выберите из данных, пожалуйста');
            end;
          until ((gametype > 0) or (gametype <= 3));
          settings := 1;
        end;  // / 3
      //
      4: BasicSet();
        
      // если вдруг пользователь дурак
      else write('Дурак!');
      end;
      writeln('Смотрите, настройки, заглянуть?');
      writeln(
        '0 - выход, 1 - новое поле, ',
        '2 - новые мины, 3 - вид клеток, ',
        '4 - вернуть начальные');
      while not TryRead(settings) do
        write('Пожалуйста введите нормальное число от 0 до 4');
  end;
  // конец настроек
  
  // спросить какую клетку проверить
  writeln('Играем!');
  writeln(
  'Введите x y, ',
  'либо "0", если не хотите играть, ',
  'либо "F", чтобы сменить режим');
  var move := 0;
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
    'Понадобилось всего ', move, ' ходов(а)');
  // Заново?
  writeln(
  '  Ещё сыграем? ',
  '0 - нет, 1 - да ');
  
  while not TryRead(EndGame) do // пока не получил число спрашивать
    writeln('Прошу ответить, будем играть? 0 = нет, 1 = да');
  if not (EndGame = 0) then
  begin
    ResetCheck(Field);
    Game()
  end
  else
    write('Всех благ!');
end;

//\\ Программа
procedure BasicSet();
begin
  
  xF := 8; yF := 11; 
  gametype := 4;
  Field := BuildTiles(xF, yF);
  mines := 10;
  Field := IniMines(Field, mines);
  gamemode := 0;
  writeln(
  'Начальные настройки: ',
  'размер = ',xF-1,' ',yF-1,' это ', (xF-1)*(yF-1),' клетки(ок), ',
  'мин ', mines, ', режим ', gametype);
  
end;

begin
  
  BasicSet();
  Game();
  
end.