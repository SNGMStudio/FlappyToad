#==============================================================================
# ■ FlappyToad
#------------------------------------------------------------------------------
# 　V1.0
#   Written by LozMov
#   A modification of Don't Touch My Birdie by Mark Steve Samson licensed under
#   Creative Commons Attribution-NonCommercial 4.0 International License.
#
#   原版地址：https://github.com/marksteve/dtmb
#   图像出处：https://github.com/tusenpo/FlappyFrog
#==============================================================================

#==============================================================================
# ■ FTConst
#------------------------------------------------------------------------------
# 　关系到游戏操作手感的各种常数。
#==============================================================================
module FTConst
  BACKGROUND_COLOR = Color.new(221,238,255) #背景颜色
  FLAPPING_SPEED = 10  #上飞速度（即每次刷新时精灵的坐标移动像素位数，下同）
  FLYING_SPEED = 5  #前行速度（实际上是柱子及栅栏向左移动的速度）
  DROPPING_SPEED = 10  #无动力时下坠速度
  CLOUD_SPEED = 1 #雾图形的移动速度
  PIPES_DISTANCE = 300 #两段柱子之间的间隔
  PIPES_GAP = 300 #柱子缺口的宽度
  GAPS_DISTANCE = 100 #两相邻柱子缺口之间上下距离的上界
  UPPER_BOUND = 310 #待机状态的浮动上界
  LOWER_BOUND = 330 #待机状态的浮动下界
  FLOATING_SPEED = 1  #浮动速度
  CHARGING_AMOUNT = 100  #每次按下决定键时获得的能量
  POWER_LIMIT = 200  #能量最大存储值
end

class FlappyToad
  include FTConst
  #--------------------------------------------------------------------------
  # ● 主处理
  #--------------------------------------------------------------------------
  def main
    #初始化得分
    @score = 0
    #初始化状态标记：
      #standby:等待操作的待机状态
      #flying:正常进行状态
      #dropping:撞击柱子后的下坠过程状态
      #gameover:游戏结束的状态
    @status = "standby"
    @power = 0 #上升动力
    @passed = false  #通过标记
    #生成背景颜色
    @background = Sprite.new
    @background.z = 1
    @background.bitmap = Bitmap.new(480,640)
    @background.bitmap.fill_rect(0,0,480,640,BACKGROUND_COLOR)
    #生成底部栅栏图形
    @ground = Viewport.new(0,640-16,480,16)
    @ground.z = 3
    @fence = Plane.new(@ground)
    @fence.bitmap = RPG::Cache.fog("fence",0)
    #生成雾图形
    @cloud = Plane.new
    @cloud.bitmap = RPG::Cache.fog("clouds",0)
    @cloud.z = 8
    @cloud.opacity = 120
    #生成角色图形
    @toad = Sprite.new
    @toad.z = 4
    @toad.bitmap = RPG::Cache.picture("toad")
    @toad.ox = @toad.bitmap.width / 2
    @toad.oy = @toad.bitmap.height / 2
    @toad.x = 100
    @toad.y = 320
    #生成柱图形（以数组形式存放）:上半段
    random_y = rand(GAPS_DISTANCE) * (rand(2) == 1 ? 1 : -1) #Y方向上的随机偏移量
    @u_pipes = []
    @pipe = Sprite.new
    @pipe.z = 2
    @pipe.bitmap = RPG::Cache.picture("u_pipe")
    @pipe.ox = @pipe.bitmap.width / 2
    @pipe.oy = @pipe.bitmap.height / 2
    @pipe.x = 500
    @pipe.y = 64 - PIPES_GAP / 2 + random_y
    @u_pipes << @pipe
    #下半段
    @l_pipes = []
    @pipe = Sprite.new
    @pipe.z = 2
    @pipe.bitmap = RPG::Cache.picture("l_pipe")
    @pipe.ox = @pipe.bitmap.width / 2
    @pipe.oy = @pipe.bitmap.height / 2
    @pipe.x = 500
    @pipe.y = 576 + PIPES_GAP / 2 + random_y
    @l_pipes << @pipe
    3.times { add_pipe }
    #生成计数文字
    @sec = Sprite.new
    @sec.z = 9
    @sec.bitmap = Bitmap.new(300,40)
    @sec.bitmap.font.name = "Arial"
    @sec.bitmap.font.size = 32
    @sec.bitmap.font.bold = true
    @sec.ox = @sec.bitmap.width / 2
    @sec.oy = @sec.bitmap.height / 2
    @sec.x = 240
    @sec.y = 260
    @sec.bitmap.font.color.set(255,100,100)
    @sec.bitmap.draw_text(@sec.bitmap.rect, "+#{@score}s", 1)
    #生成提示文字（只在游戏结束后可见）
    @restart = Sprite.new
    @restart.z = 9
    @restart.bitmap = Bitmap.new(300,40)
    @restart.bitmap.font.name = "Arial"
    @restart.bitmap.font.size = 32
    @restart.bitmap.font.bold = true
    @restart.ox = @restart.bitmap.width / 2
    @restart.oy = @restart.bitmap.height / 2
    @restart.x = 240
    @restart.y = 400
    @restart.visible = false
    @restart.bitmap.font.color.set(255,100,100)
    @restart.bitmap.draw_text(@restart.bitmap.rect, "按E重新开始", 1)
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      if $scene != self
        break
      end
    end
    Graphics.freeze
  end
  #--------------------------------------------------------------------------
  # ● 刷新画面
  #--------------------------------------------------------------------------
  def update
    #雾图形的滚动
    @cloud.ox += CLOUD_SPEED
    #依据状态决定画面刷新模式
    case @status
    when "standby"
      standby_update
    when "flying"
      flying_update
    when "dropping"
      dropping_update
    when "gameover"
      gameover_update
    end
  end
  def standby_update  #待机状态下角色的上下浮动
    #栅栏的滚动
    @fence.ox += FLYING_SPEED
    if @toad.y == UPPER_BOUND #判断是否到达浮动上界
      @u_reached = true
      @l_reached = false
    end
    if @toad.y == LOWER_BOUND #判断是否到达浮动下界
      @l_reached = true 
      @u_reached = false
    end
    if @l_reached  #开始上移
      @toad.y -= FLOATING_SPEED
    elsif @u_reached #开始下移
      @toad.y += FLOATING_SPEED
    else  #初始移动方向(下移)
      @toad.y += FLOATING_SPEED
    end
    if Input.trigger?(Input::C)
      Audio.se_play("Audio/SE/flap")
      @power += CHARGING_AMOUNT
      @status = "flying"
    end
  end
  
  def flying_update  #正常状态
    #栅栏和柱子的滚动
    @fence.ox += FLYING_SPEED
    @u_pipes.each { |pipe| pipe.x -= FLYING_SPEED }
    @l_pipes.each { |pipe| pipe.x -= FLYING_SPEED }
    if @u_pipes.size <= 4
      add_pipe
    end
    if @u_pipes.first.x <= -20
      @u_pipes.shift.dispose
      @l_pipes.shift.dispose
      @passed = false  #重置通过标记
    end
    if @power > 0  #若有动力则消耗动力上升
      @power = POWER_LIMIT if @power > POWER_LIMIT  #削减能量至上限
      @toad.angle = 0 if @toad.angle < 0  #消除下倾状态
      @power -= FLAPPING_SPEED
      @toad.y -= FLAPPING_SPEED if @toad.y >= 0
    else  #若无动力则下坠，直到接触地面
      if @toad.y <= 630
        @toad.y += DROPPING_SPEED 
        @toad.angle -= 2 if @toad.angle >= -50  #图形下倾
      else
        @toad.angle = -180
        @toad.mirror = true
        @restart.visible = true
        #@sec.bitmap.clear
        #@sec.bitmap.draw_text(@sec.bitmap.rect, "?", 1)
        Audio.se_play("Audio/SE/hurt")
        @status = "gameover"
      end
    end
    #判断是否通过柱子
    if @toad.x - @toad.ox >= @u_pipes.first.x - @u_pipes.first.ox && !@passed
      Audio.se_play("Audio/SE/score")
      #重新绘制记数文字
      @score += 1
      @sec.bitmap.clear
      @sec.bitmap.draw_text(@sec.bitmap.rect, "+#{@score}s", 1)
      @passed = true
    end
    if hit?  #撞击后
      @status = "dropping"
    end
    if Input.trigger?(Input::C)
      Audio.se_play("Audio/SE/flap")
      @power += CHARGING_AMOUNT
    end

  end
  
  def dropping_update  #撞击柱子后
    @toad.angle = -180
    @toad.mirror = true
    @restart.visible = true
    #@sec.bitmap.clear
    #@sec.bitmap.draw_text(@sec.bitmap.rect, "?", 1)
    Audio.se_play("Audio/SE/hurt")
    until @toad.y >= 630  #进入下坠过程
      @toad.y += DROPPING_SPEED * 2
      Graphics.update
    end
    @status = "gameover"
  end
  
  def gameover_update  #游戏结束后的选择界面
    if MyBoard.press?(MyBoard::Key_E)
      #raise Reset  #引发重置
      @power = 0 #上升动力
      @passed = false  #通过标记
      #角色复位
      @toad.mirror = false
      @toad.angle = 0
      @toad.x = 100
      @toad.y = 320
      #重新生成柱图形：上半段
      @u_pipes.shift.dispose until @u_pipes.empty?  #释放全部位图
      random_y = rand(GAPS_DISTANCE) * (rand(2) == 1 ? 1 : -1) #Y方向上的随机偏移量
      @pipe = Sprite.new
      @pipe.z = 2
      @pipe.bitmap = RPG::Cache.picture("u_pipe")
      @pipe.ox = @pipe.bitmap.width / 2
      @pipe.oy = @pipe.bitmap.height / 2
      @pipe.x = 500
      @pipe.y = 64 - PIPES_GAP / 2 + random_y
      @u_pipes << @pipe
      #下半段
      @l_pipes.shift.dispose until @l_pipes.empty?
      @pipe = Sprite.new
      @pipe.z = 2
      @pipe.bitmap = RPG::Cache.picture("l_pipe")
      @pipe.ox = @pipe.bitmap.width / 2
      @pipe.oy = @pipe.bitmap.height / 2
      @pipe.x = 500
      @pipe.y = 576 + PIPES_GAP / 2 + random_y
      @l_pipes << @pipe
      3.times { add_pipe }
      @restart.visible = false
      @score = 0
      @sec.bitmap.clear
      @sec.bitmap.draw_text(@sec.bitmap.rect, "+#{@score}s", 1)
      @status = "standby"
    end
  end
  
  def add_pipe  #在画面外添加柱子以备显示
    random_y = rand(GAPS_DISTANCE) * (rand(2) == 1 ? 1 : -1) #Y方向上的随机偏移量
    #上半段
    @pipe = Sprite.new
    @pipe.z = 2
    @pipe.bitmap = RPG::Cache.picture("u_pipe")
    @pipe.ox = @pipe.bitmap.width / 2
    @pipe.oy = @pipe.bitmap.height / 2
    @pipe.y = 64 - PIPES_GAP / 2 + random_y
    @pipe.x = @u_pipes.last.x + PIPES_DISTANCE
    @u_pipes << @pipe
    #下半段
    @pipe = Sprite.new
    @pipe.z = 2
    @pipe.bitmap = RPG::Cache.picture("l_pipe")
    @pipe.ox = @pipe.bitmap.width / 2
    @pipe.oy = @pipe.bitmap.height / 2
    @pipe.y = 576 + PIPES_GAP / 2 + random_y
    @pipe.x = @l_pipes.last.x + PIPES_DISTANCE
    @l_pipes << @pipe
  end
  
  def hit?  #判断是否撞击柱子（简化为判断位图矩形4点是否在柱子的范围内）
    trect = @toad.bitmap.rect
    trect.x = @toad.x - @toad.ox
    trect.y = @toad.y - @toad.oy
    urect = @u_pipes.first.bitmap.rect
    urect.x = @u_pipes.first.x - @u_pipes.first.ox
    urect.y = @u_pipes.first.y - @u_pipes.first.oy
    lrect = @l_pipes.first.bitmap.rect
    lrect.x = @l_pipes.first.x - @l_pipes.first.ox
    lrect.y = @l_pipes.first.y - @l_pipes.first.oy
    tax,tay = trect.x,trect.y
    tbx,tby = trect.x,trect.y + trect.height
    tcx,tcy = trect.x + trect.width,trect.y + trect.height
    tdx,tdy = trect.x + trect.width,trect.y
    ux_range = (urect.x)..(urect.x + urect.width)
    uy_range = (urect.y)..(urect.y + urect.height)
    lx_range = (lrect.x)..(lrect.x + lrect.width)
    ly_range = (lrect.y)..(lrect.y + lrect.height)
    if (ux_range.include?(tax) && uy_range.include?(tay)) ||
      (ux_range.include?(tbx) && uy_range.include?(tby)) ||
      (ux_range.include?(tcx) && uy_range.include?(tcy)) ||
      (ux_range.include?(tdx) && uy_range.include?(tdy)) then  #撞击上部
      return true
    elsif (lx_range.include?(tax) && ly_range.include?(tay)) ||
      (lx_range.include?(tbx) && ly_range.include?(tby)) ||
      (lx_range.include?(tcx) && ly_range.include?(tcy)) ||
      (lx_range.include?(tdx) && ly_range.include?(tdy)) then  #撞击下部
      return true
    end
    return false
  end
  
end

#为使用Input模块不能处理的部分按键而临时编写的脚本。by失落的乐章
module MyBoard
  GKS = Win32API.new('user32.dll', 'GetKeyState', 'i', 'i')
  Key_E         = 0x45        # E key
  Key_M         = 0x4D        # M key
  Key_P         = 0x50        # P key
  Key_5         = 0x35        # 5 key
  Key_NUMPAD5   = 0x65        # Numeric keypad 5 key
  Key_7         = 0x37        # 7 key
  Key_NUMPAD7   = 0x67        # Numeric keypad 7 key
  Key_0         = 0x30        # 0 key
  Key_NUMPAD0   = 0x60        # Numeric keypad 0 key
  
  def self.press?(key)
    GKS.call(key) < 0
  end
  
end

#===============================================================================
# Custom Resolution
# Authors: ForeverZer0, KK20
# Version: 0.96b
# Date: 11.15.2013
#===============================================================================
#此段脚本仅保留了处理自定分辨率下Plane及Viewport显示的部分。
#完整版可到此处下载：http://forum.chaos-project.com/index.php/topic,7814.0.html
#===============================================================================
# ** Viewport
#===============================================================================
class Viewport
 
  alias zer0_viewport_resize_init initialize unless $@
  def initialize(x=0, y=0, width=480, height=640, override=false)
    if x.is_a?(Rect)
      # If first argument is a Rectangle, just use it as the argument.
      zer0_viewport_resize_init(x)
    elsif [x, y, width, height] == [0, 0, 640, 480] && !override
      # Resize fullscreen viewport, unless explicitly overridden.
      zer0_viewport_resize_init(Rect.new(0, 0, 480, 640))
    else
      # Call method normally.
      zer0_viewport_resize_init(Rect.new(x, y, width, height))
    end
  end
 
  def resize(*args)
    # Resize the viewport. Can call with (X, Y, WIDTH, HEIGHT) or (RECT).
    self.rect = args[0].is_a?(Rect) ? args[0] : Rect.new(*args)
  end
end

#===============================================================================
# ** Plane
#===============================================================================
 
class Plane < Sprite
 
  def z=(z)
    # Change the Z value of the viewport, not the sprite.
    super(z * 1000)
  end
 
  def ox=(ox)
    return if @bitmap == nil
    # Have viewport stay in loop on X-axis.
    super(ox % @bitmap.width)
  end
 
  def oy=(oy)
    return if @bitmap == nil
    # Have viewport stay in loop on Y-axis.
    super(oy % @bitmap.height)
  end
 
  def bitmap
    # Return the single bitmap, before it was tiled.
    return @bitmap
  end
 
  def bitmap=(tile)
    @bitmap = tile
    # Calculate the number of tiles it takes to span screen in both directions.
    xx = 1 + (480.to_f / tile.width).ceil
    yy = 1 + (640.to_f / tile.height).ceil
    # Create appropriately sized bitmap, then tile across it with source image.
    plane = Bitmap.new(@bitmap.width * xx, @bitmap.height * yy)
    (0..xx).each {|x| (0..yy).each {|y|
      plane.blt(x * @bitmap.width, y * @bitmap.height, @bitmap, @bitmap.rect)
    }}
    # Set the bitmap to the sprite through its super class (Sprite).
    super(plane)
  end
 
  # Redefine methods dealing with coordinates (defined in super) to do nothing.
  def x; end
  def y; end
  def x=(x); end
  def y=(y); end
end
