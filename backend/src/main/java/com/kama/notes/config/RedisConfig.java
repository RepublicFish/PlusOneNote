package com.kama.notes.config;

import com.fasterxml.jackson.annotation.JsonTypeInfo;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

@Configuration
public class RedisConfig {

    /**
     * 构建用于 Redis 值序列化的 JSON 序列化器。
     *
     * 注意：不能直接使用 new GenericJackson2JsonRedisSerializer() 的无参构造，
     * 它内部是默认的 ObjectMapper，未注册 Java 8 时间模块，
     * 一旦被缓存的对象含有 LocalDateTime / LocalDate 字段（如 Note、User），
     * 写入 Redis 时会抛 SerializationException：
     *   "Java 8 date/time type `java.time.LocalDateTime` not supported by default"
     * 例如搜索接口缓存搜索结果时就会因此返回 500/400。
     */
    private GenericJackson2JsonRedisSerializer buildJsonSerializer() {
        ObjectMapper mapper = new ObjectMapper();

        // 1. 注册 Java 8 时间模块，支持 LocalDateTime / LocalDate / LocalTime
        mapper.registerModule(new JavaTimeModule());
        // 2. 时间以 ISO-8601 字符串写入，而不是默认的时间戳数组，便于排查
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        // 3. 保留类型信息（与无参构造的默认行为一致），
        //    否则反序列化会退化成 LinkedHashMap，取出来无法还原成原始对象
        mapper.activateDefaultTyping(
                LaissezFaireSubTypeValidator.instance,
                ObjectMapper.DefaultTyping.NON_FINAL,
                JsonTypeInfo.As.PROPERTY);

        return new GenericJackson2JsonRedisSerializer(mapper);
    }

    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory factory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(factory);
        // 使用 String 序列化键（key）
        template.setKeySerializer(new StringRedisSerializer());
        // 使用 JSON 序列化值（value）
        template.setValueSerializer(buildJsonSerializer());
        // 使用 String 序列化哈希键（hash key）和值（hash value）
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(buildJsonSerializer());
        return template;
    }

    @Bean
    public StringRedisTemplate stringRedisTemplate(RedisConnectionFactory redisConnectionFactory) {
        return new StringRedisTemplate(redisConnectionFactory);
    }
}
