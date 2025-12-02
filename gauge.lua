require 'cairo'

local IMG_PATH = "/home/Reneto/.conky/cpu-gauge-analog/gauge.png"

-- Dibuja la imagen base (los 2 relojes juntos)
local function draw_base(cr, x, y)
    local img = cairo_image_surface_create_from_png(IMG_PATH)
    local w   = cairo_image_surface_get_width(img)
    local h   = cairo_image_surface_get_height(img)

    cairo_set_source_surface(cr, img, x, y)
    cairo_paint(cr)
    cairo_surface_destroy(img)

    return w, h
end

-- Aguja (ROJA) calibrada según tu imagen real
local function draw_needle(cr, cx, cy, value, length)
    local v = math.max(0, math.min(100, value))

    -- Ajuste afinado para que coincida con tu dial
    local MIN_ANGLE_DEG = -255   -- posición real para 0%
    local MAX_ANGLE_DEG =   95   -- posición real para 100%

    local angle_deg = MIN_ANGLE_DEG + v * (MAX_ANGLE_DEG - MIN_ANGLE_DEG) / 100.0
    local angle = angle_deg * math.pi / 180

    cairo_set_source_rgba(cr, 1, 0, 0, 1)
    cairo_set_line_width(cr, 4)

    cairo_move_to(cr, cx, cy)
    cairo_line_to(
        cr,
        cx + length * math.cos(angle),
        cy + length * math.sin(angle)
    )
    cairo_stroke(cr)
end


-- Texto centrado (para los porcentajes)
local function draw_text_center(cr, text, x, y, size)
    cairo_select_font_face(cr, "Ubuntu", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD)
    cairo_set_font_size(cr, size)
    cairo_set_source_rgba(cr, 1, 1, 1, 1)

    local ext = cairo_text_extents_t:create()
    cairo_text_extents(cr, text, ext)

    local tx = x - (ext.width / 2 + ext.x_bearing)
    local ty = y - (ext.height / 2 + ext.y_bearing)
    cairo_move_to(cr, tx, ty)
    cairo_show_text(cr, text)
end

function conky_main()
    if conky_window == nil then return end

    local w = conky_window.width
    local h = conky_window.height

    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        w, h
    )
    local cr = cairo_create(cs)
    cairo_set_antialias(cr, CAIRO_ANTIALIAS_BEST)

    -- Posición de la imagen completa en la ventana
    local x0 = 70
    local y0 = -20

    -- Dibuja la imagen (los dos relojes juntos)
    local iw, ih = draw_base(cr, x0, y0)

    ------------------------------------------------
    -- CENTROS DE LOS Diales (ajuste fino)
    ------------------------------------------------
    -- CPU (dial grande, izquierda)
    local cpu_cx = x0 + 65
    local cpu_cy = y0 + 95

    -- RAM (dial chico, derecha)
    local ram_cx = x0 + 133
    local ram_cy = y0 + 65
    ------------------------------------------------

    -- Valores reales del sistema
    local cpu = tonumber(conky_parse("${cpu}")) or 0
    local ram = tonumber(conky_parse("${memperc}")) or 0

    -- Longitud de agujas
    draw_needle(cr, cpu_cx, cpu_cy, cpu, 32)   -- CPU
    draw_needle(cr, ram_cx,  ram_cy,  ram, 30) -- RAM

    -- ============================
    --  PORCENTAJES DINÁMICOS
    -- ============================
    local cpu_text = string.format("%02d%%", cpu)
    local ram_text = string.format("%02d%%", ram)

    -- Coordenadas aproximadas encima del texto "CPU" y "RAM"
    -- (estas son las que ya te gustaban)
    local cpu_txt_x = cpu_cx
    local cpu_txt_y = y0 + 136   -- encima del cuadro CPU

    local ram_txt_x = ram_cx
    local ram_txt_y = y0 + 90   -- encima del cuadro RAM

    draw_text_center(cr, cpu_text, cpu_txt_x, cpu_txt_y, 9)
    draw_text_center(cr, ram_text, ram_txt_x, ram_txt_y, 8)

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
